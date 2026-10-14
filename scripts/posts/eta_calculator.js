export function calculateTrip({ distance, estimatedHours, estimatedMinutes, drivingSpeed, breakMinutes, departure }) {
    if (![distance, drivingSpeed].every(value => Number.isFinite(value) && value > 0)) {
        throw new Error('Enter a distance and driving speed greater than zero.');
    }
    if (!Number.isSafeInteger(estimatedHours) || estimatedHours < 0 ||
        !Number.isInteger(estimatedMinutes) || estimatedMinutes < 0 || estimatedMinutes > 59) {
        throw new Error('Enter Google Maps trip time using whole hours (0 or more) and minutes (0-59).');
    }
    const baselineMinutes = estimatedHours * 60 + estimatedMinutes;
    if (baselineMinutes === 0) {
        throw new Error('Google Maps trip time must be greater than zero.');
    }
    if (!Number.isFinite(breakMinutes) || breakMinutes < 0) {
        throw new Error('Enter zero or more minutes for breaks.');
    }
    if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(departure)) {
        throw new Error('Enter a valid departure time.');
    }

    const drivingMinutes = distance / drivingSpeed * 60;
    if (![baselineMinutes, drivingMinutes].every(minutes =>
        Number.isFinite(minutes) && minutes > 0 &&
        minutes + breakMinutes < Number.MAX_SAFE_INTEGER - 1440)) {
        throw new Error('These values produce a trip duration outside the supported range.');
    }
    const estimatedSpeed = distance / (baselineMinutes / 60);
    if (!Number.isFinite(estimatedSpeed)) {
        throw new Error('These values produce an average speed outside the supported range.');
    }
    const [hours, minutes] = departure.split(':').map(Number);
    return {
        baselineMinutes,
        estimatedSpeed,
        drivingMinutes,
        breakMinutes,
        departureMinutes: hours * 60 + minutes,
        drivingSaved: baselineMinutes - drivingMinutes,
        totalSaved: baselineMinutes - (drivingMinutes + breakMinutes)
    };
}

export function formatDuration(minutes) {
    const rounded = Math.round(minutes);
    const hours = Math.floor(rounded / 60);
    return hours ? `${hours} hr ${rounded % 60} min` : `${rounded} min`;
}

export function formatArrival(departureMinutes, durationMinutes) {
    const total = departureMinutes + Math.round(durationMinutes);
    const days = Math.floor(total / 1440);
    const hour = Math.floor(total % 1440 / 60);
    const minute = String(total % 60).padStart(2, '0');
    const time = `${hour % 12 || 12}:${minute} ${hour < 12 ? 'am' : 'pm'}`;
    return days ? `${time} (+${days} ${days === 1 ? 'day' : 'days'})` : time;
}

export function initEtaCalculator(container) {
    const calculator = container.querySelector('[data-eta-calculator]');
    if (!calculator) return;

    const form = calculator.querySelector('form');
    const error = calculator.querySelector('[data-eta-error]');
    const results = calculator.querySelector('[data-eta-results]');
    const rows = results.querySelector('tbody');
    const estimatedSpeed = calculator.querySelector('[data-eta-estimated-speed]');

    function update() {
        const number = name => form.elements.namedItem(name).valueAsNumber;
        let trip;
        try {
            trip = calculateTrip({
                distance: number('distance'),
                estimatedHours: number('estimatedHours'),
                estimatedMinutes: number('estimatedMinutes'),
                drivingSpeed: number('drivingSpeed'),
                breakMinutes: number('breakMinutes'),
                departure: form.elements.namedItem('departure').value
            });
        } catch (problem) {
            if (!(problem instanceof Error)) throw problem;
            error.textContent = problem.message;
            estimatedSpeed.textContent = '--';
            results.hidden = true;
            return;
        }

        error.textContent = '';
        estimatedSpeed.textContent = `${trip.estimatedSpeed.toFixed(1)} mph`;
        rows.replaceChildren();
        const scenarios = [
            ['Google Maps estimate', trip.baselineMinutes, 0],
            ['Google Maps estimate + breaks', trip.baselineMinutes, trip.breakMinutes],
            ['Your speed, no breaks', trip.drivingMinutes, 0],
            ['Your speed, with breaks', trip.drivingMinutes, trip.breakMinutes]
        ];
        for (const [label, driving, breaks] of scenarios) {
            const row = document.createElement('tr');
            const values = [
                label,
                formatDuration(driving + breaks),
                formatArrival(trip.departureMinutes, driving + breaks)
            ];
            for (const [index, value] of values.entries()) {
                const cell = document.createElement(index === 0 ? 'th' : 'td');
                if (index === 0) cell.scope = 'row';
                cell.textContent = value;
                row.append(cell);
            }
            rows.append(row);
        }
        results.hidden = false;
    }

    form.addEventListener('input', update);
    form.addEventListener('submit', event => {
        event.preventDefault();
        update();
    });
    update();
}
