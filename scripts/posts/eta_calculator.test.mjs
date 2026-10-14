import test from 'node:test';
import assert from 'node:assert/strict';
import { calculateTrip, formatArrival, formatDuration } from './eta_calculator.js';

const defaults = {
    distance: 360,
    estimatedHours: 6,
    estimatedMinutes: 0,
    drivingSpeed: 70,
    breakMinutes: 30,
    departure: '06:00'
};

test('360-mile example keeps driving savings separate from breaks', () => {
    const trip = calculateTrip(defaults);
    assert.ok(Math.abs(trip.drivingSaved - 360 / 7) < 1e-10);
    assert.ok(Math.abs(trip.totalSaved - (360 / 7 - 30)) < 1e-10);
    assert.equal(formatDuration(trip.drivingMinutes), '5 hr 9 min');
    assert.equal(formatArrival(trip.departureMinutes, trip.drivingMinutes), '11:09 am');
    assert.equal(formatArrival(trip.departureMinutes, trip.drivingMinutes + 30), '11:39 am');
    assert.equal(formatArrival(trip.departureMinutes, trip.baselineMinutes + 30), '12:30 pm');
    const slower = calculateTrip({ ...defaults, drivingSpeed: 65 });
    assert.equal(formatArrival(slower.departureMinutes, slower.drivingMinutes), '11:32 am');
    assert.equal(formatArrival(slower.departureMinutes, slower.drivingMinutes + 30), '12:02 pm');
});

test('two- and three-hour baseline trips do not multiply rounded savings', () => {
    for (const [distance, saved] of [[120, 17], [180, 26]]) {
        const trip = calculateTrip({ ...defaults, distance, estimatedHours: distance / 60 });
        assert.equal(Math.round(trip.drivingSaved), saved);
    }
});

test('Google Maps duration sets the baseline without changing your driving time', () => {
    const original = calculateTrip(defaults);
    const longer = calculateTrip({ ...defaults, estimatedHours: 7, estimatedMinutes: 15 });
    assert.equal(longer.baselineMinutes, 435);
    assert.equal(longer.drivingMinutes, original.drivingMinutes);
    assert.ok(Math.abs(longer.drivingSaved - original.drivingSaved - 75) < 1e-10);
    assert.equal(formatArrival(longer.departureMinutes, longer.baselineMinutes), '1:15 pm');
    const short = calculateTrip({
        ...defaults, distance: 30, estimatedHours: 0, estimatedMinutes: 45,
        drivingSpeed: 60, breakMinutes: 0
    });
    assert.equal(short.drivingSaved, 15);
    assert.equal(short.totalSaved, 15);
});

test('equal speeds, slower speeds, and breaks can mean no savings or a later arrival', () => {
    const equal = calculateTrip({ ...defaults, drivingSpeed: 60 });
    assert.equal(equal.drivingSaved, 0);
    assert.equal(equal.totalSaved, -30);
    const slower = calculateTrip({ ...defaults, drivingSpeed: 40, breakMinutes: 0 });
    assert.equal(slower.drivingSaved, -180);
    assert.equal(slower.totalSaved, -180);
});

test('implied average speed uses Maps duration and distance, not your speed or breaks', () => {
    assert.equal(calculateTrip(defaults).estimatedSpeed, 60);
    assert.equal(calculateTrip({ ...defaults, distance: 180 }).estimatedSpeed, 30);
    assert.equal(calculateTrip({
        ...defaults, estimatedHours: 7, estimatedMinutes: 30
    }).estimatedSpeed, 48);
    assert.equal(calculateTrip({
        ...defaults, distance: 30, estimatedHours: 0, estimatedMinutes: 45
    }).estimatedSpeed, 40);
    assert.equal(calculateTrip({
        ...defaults, drivingSpeed: 50, breakMinutes: 120
    }).estimatedSpeed, 60);
});

test('arrivals handle midnight, multiple days, and rounding across midnight', () => {
    assert.equal(formatArrival(23 * 60, 120), '1:00 am (+1 day)');
    assert.equal(formatArrival(6 * 60, 2880), '6:00 am (+2 days)');
    assert.equal(formatArrival(23 * 60 + 59, 0.6), '12:00 am (+1 day)');
});

test('invalid values show errors instead of impossible trip estimates', () => {
    for (const field of ['distance', 'drivingSpeed']) {
        for (const value of [0, -1, NaN, Infinity]) {
            assert.throws(() => calculateTrip({ ...defaults, [field]: value }), /greater than zero/);
        }
        for (const estimatedHours of [-1, 1.5, NaN, Infinity]) {
            assert.throws(() => calculateTrip({ ...defaults, estimatedHours }), /Google Maps trip time/);
        }
        for (const estimatedMinutes of [-1, 60, 0.5, NaN, Infinity]) {
            assert.throws(() => calculateTrip({ ...defaults, estimatedMinutes }), /Google Maps trip time/);
        }
        assert.throws(() => calculateTrip({
            ...defaults, estimatedHours: 0, estimatedMinutes: 0
        }), /greater than zero/);
    }
    for (const breakMinutes of [-1, NaN, Infinity]) {
        assert.throws(() => calculateTrip({ ...defaults, breakMinutes }), /breaks/);
    }
    for (const departure of ['', '24:00', '12:60']) {
        assert.throws(() => calculateTrip({ ...defaults, departure }), /departure/);
    }
    assert.throws(() => calculateTrip({ ...defaults, distance: Number.MAX_VALUE }), /supported range/);
});
