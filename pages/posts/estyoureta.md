# Try calculating your ETA

I've been on a couple of super long road trips in the last couple of years.
While driving, I wondered quite a few times, what is my ETA compared
to the one Google Maps suggested when I started the trip?

In the post, I assume that Google Maps' suggested routes and ETA are
accurate if you are driving with the flow of traffic.

I am considering the average flow of traffic since Google Maps estimates the ETA by
averaging the speed of the flow of traffic [1]. It makes sense when the roads
are so busy, but I am assuming that Google Maps does the same when cars are speeding
(driving at speeds above the speed limit).

I always thought of doing these calculations after finishing the trip, but it
never happened. So this time I did some easy calculations while driving. If
the average flow of traffic is 60 mph over the entire trip and if I have to drive
60 miles, I'll reach the destination in 60 mins. Now if I avg 70 miles per hour
by not exceeding the speed limit by +10, I'll reach the destination in 6/7 hrs
(~0.86 hrs/ ~51 mins). So if you do it for 2 hours, you might save ~17 mins and
it's ~26 mins for 3 hours. Not sure how aggressive ppl are while driving long
distances, but I usually take a 10-15 min break every 2 - 3 hrs. For this
calculation, let's say we are driving 360 miles. I might take 2 to 3 breaks which
take 30 mins. If I am averaging a speed of 70 over the entire journey driving
mostly highways, I'll reach the destination ~51 mins earlier, minus 30 mins (for the
breaks), viz., ETA - 21 mins in the best case. If I was avg'ing 60, it would've
been ETA +30 mins. So if I started at 6 am and averaged 60 mph with no breaks, I
would've arrived at 12 pm. If I took breaks, I would've arrived at 12:30 pm. If I
averaged 70 mph, I might've arrived around 11:39 am with 30 mins of breaks. IMO
averaging 70 mph is hard (also depends on where you are driving ig), so if you
averaged 65 mph, then you might've arrived around 12:02 pm with 30 mins of breaks.
So at 60 - 70 mph with 30 mins of breaks, my ETA
might oscillate between Google Maps suggested ETA - 21 mins and ETA + 30
for 6 hr long drives. It's good to have this calculation in your head instead of
Google Maps, based on your driving style, I think. It helps with making plans with
friends and trying to visit a place when timing matters.

Since these calculations are really messy, I've asked AI to create a calculator.
The ideal solution would be to have a smart assistant that could analyze your
driving behaviour and suggest your estimates. IMO this will not only help to
estimate more accurate ETAs but also help to identify changes in driving
patterns. Pattern recognition in a person actions is an interesting thing to
explore. For now, please settle for a boring calculator for your ETAs.
After finishing the first draft I've realized maybe I should have parking time
since some cities are cursed.

<section class="eta-calculator" data-eta-calculator aria-label="ETA calculator">
<form>
<div class="eta-fields">
<label for="eta-distance">Distance (miles)
<input id="eta-distance" name="distance" type="number" min="0" step="any" value="360" required></label>
<div class="eta-time-field">
<span id="eta-time-label">Google Maps trip time</span>
<div class="eta-time-box" role="group" aria-labelledby="eta-time-label">
<label for="eta-estimated-hours"><input id="eta-estimated-hours" name="estimatedHours" type="number" min="0" step="1" value="6" required>hours</label>
<label for="eta-estimated-minutes"><input id="eta-estimated-minutes" name="estimatedMinutes" type="number" min="0" max="59" step="1" value="0" required>min</label>
</div>
</div>
<label for="eta-implied-speed">Google Maps' implied average speed
<output id="eta-implied-speed" for="eta-distance eta-estimated-hours eta-estimated-minutes" data-eta-estimated-speed>--</output></label>
<label for="eta-speed">Your average driving speed (mph)
<input id="eta-speed" name="drivingSpeed" type="number" min="0" step="any" value="70" required></label>
<label for="eta-breaks">Total break time (minutes)
<input id="eta-breaks" name="breakMinutes" type="number" min="0" step="any" value="30" required></label>
<label for="eta-departure">Departure time
<input id="eta-departure" name="departure" type="time" value="06:00" required></label>
</div>
<button type="submit">Calculate ETA</button>
</form>
<p data-eta-error role="status">Loading calculator. JavaScript must be enabled to use it.</p>
<div data-eta-results aria-live="polite" aria-atomic="true" hidden>
<div class="eta-table-scroll" role="region" aria-label="Trip comparison" tabindex="0">
<table>
<caption>Same distance and departure time for every scenario</caption>
<thead><tr><th scope="col">Scenario</th><th scope="col">Total trip time</th><th scope="col">Arrival</th></tr></thead>
<tbody></tbody>
</table>
</div>
</div>
</section>

[1] https://blog.google/products-and-platforms/products/maps/google-maps-101-how-ai-helps-predict-traffic-and-determine-routes/
