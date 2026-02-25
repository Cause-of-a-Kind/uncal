# Phase 5 — Availability Calculation Engine

## Goal

Build the core engine that computes available time slots by intersecting all members' availability, subtracting busy times, and respecting all scheduling constraints.

## Tasks

- [x] Create `AvailabilityCalculator` service: `AvailabilityCalculator.new(schedule_link, date)`
- [x] Returns array of `{ start_time: DateTime, end_time: DateTime }` in UTC
- [x] Implement the 10-step slot generation algorithm (see below)
- [x] Create `TimeSlotHelper` utility with range operations
- [x] Add caching layer for Google Calendar busy times (5-minute TTL via Solid Cache)
- [x] Invalidate cache on new booking creation
- [x] Create public availability API endpoint (no auth required)
- [x] `GET /book/:slug/availability?date=2026-03-04&timezone=America/New_York`
- [x] Returns JSON array of available slots in requester's timezone

## 10-Step Slot Generation Algorithm

For a given `schedule_link` and `date`:

1. **Determine day_of_week** for the date in the schedule link's timezone
2. **Reject past dates** — if date is in the past, return empty
3. **Reject beyond max_future_days** — if date is beyond `max_future_days` from today, return empty
4. **For each member** of the schedule link:
   - (a) Get their `AvailabilityWindow` records for that `day_of_week` on this link
   - (b) Convert window times to UTC for the specific date (e.g., "09:00 America/New_York on 2026-03-04" → UTC datetime)
   - (c) Fetch Google Calendar busy times for that date (if connected, use cache)
   - (d) Subtract busy times from availability windows = member's free slots
5. **Intersect** all members' free slots = combined availability (time must be free for ALL members)
6. **Get existing confirmed bookings** for this schedule_link on this date
7. **Check max_bookings_per_day** — if set and count >= limit, return empty
8. **Subtract bookings with buffer** — each booking blocks: `start_time` to `(end_time + buffer_minutes)`
9. **Split into slots** — divide remaining free time into slots of `meeting_duration_minutes`, starting on 15-minute boundaries; slot only valid if entire duration fits within a free block
10. **Return** the list of available start times

## TDD Cycles

### Cycle 1: TimeSlotHelper — Range Operations
- [x] Test: `intersect_ranges` with two overlapping ranges returns overlap
- [x] Test: `intersect_ranges` with non-overlapping ranges returns empty
- [x] Test: `intersect_ranges` with multiple ranges on each side
- [x] Test: `intersect_ranges` where one range fully contains the other
- [x] Test: `subtract_ranges` removes a middle section (splits base range)
- [x] Test: `subtract_ranges` removes start of base range
- [x] Test: `subtract_ranges` removes end of base range
- [x] Test: `subtract_ranges` with no overlap returns base unchanged
- [x] Test: `subtract_ranges` with complete overlap returns empty
- [x] Test: `subtract_ranges` with multiple subtractions
- [x] Test: `split_into_slots` divides a range into 30-minute slots
- [x] Test: `split_into_slots` starts on 15-minute boundaries
- [x] Test: `split_into_slots` drops partial slots that don't fit
- [x] Test: `split_into_slots` with custom interval (e.g., 15-minute)
- [x] Test: `split_into_slots` with multiple non-contiguous ranges
- [x] Implement: `app/services/time_slot_helper.rb`

### Cycle 2: AvailabilityCalculator — Single Member
- [x] Test: returns available slots for a member with one availability window
- [x] Test: returns empty for a past date
- [x] Test: returns empty for a date beyond `max_future_days`
- [x] Test: subtracts Google Calendar busy times from availability
- [x] Test: returns empty when member has no windows for that day
- [x] Test: handles member with multiple windows on same day
- [x] Test: converts availability window times to UTC correctly
- [x] Implement: basic `AvailabilityCalculator` for single member

### Cycle 3: AvailabilityCalculator — Multi-Member & Constraints
- [x] Test: intersects availability across two members (only mutual free times)
- [x] Test: returns empty when members have no overlapping availability
- [x] Test: works without Booking model (graceful `respond_to?` guard)
- [x] Test: max_bookings_per_day set but no bookings → still returns slots
- [ ] Test: subtracts existing confirmed bookings from availability (Phase 6)
- [ ] Test: booking subtraction includes buffer minutes (Phase 6)
- [ ] Test: returns empty when `max_bookings_per_day` reached (Phase 6)
- [ ] Test: cancelled bookings don't count against availability (Phase 6)
- [x] Implement: multi-member intersection, booking/buffer subtraction (guarded)

### Cycle 4: DST & Edge Cases
- [x] Test: correct slot generation across DST spring-forward transition
- [x] Test: late-night window where UTC conversion crosses date boundary
- [x] Test: today's date only shows future slots (not past times today)
- [x] Implement: DST handling, edge case coverage

### Cycle 5: Caching Layer
- [x] Test: Google Calendar busy times cached with 5-minute TTL
- [x] Test: second call within TTL uses cached data (no API call)
- [x] Test: cache miss triggers API call and stores result
- [x] Test: `invalidate_busy_cache` forces fresh fetch
- [x] Implement: Solid Cache integration in `GoogleCalendarService`

### Cycle 6: Public Availability API
- [x] Test: `GET /book/:slug/availability?date=...&timezone=...` returns JSON
- [x] Test: response contains array of `{start_time, end_time}` in requester's timezone
- [x] Test: no authentication required
- [x] Test: invalid slug returns 404
- [x] Test: missing date param returns 400
- [x] Test: inactive schedule link returns 404
- [x] Implement: `AvailabilityController`, route

## Key Files

```
app/services/availability_calculator.rb
app/services/time_slot_helper.rb
app/controllers/availability_controller.rb
config/routes.rb (updated)
test/services/availability_calculator_test.rb
test/services/time_slot_helper_test.rb
test/controllers/availability_controller_test.rb
```

## Acceptance Criteria

- [x] Correctly computes availability across multiple members
- [x] Respects all constraints: availability windows, Google Calendar busy times, existing bookings, buffer, max per day, max future days, no past dates
- [x] Slots split on 15-minute boundaries
- [x] All times stored in UTC, converted for display
- [x] Availability endpoint returns slots in requester's timezone
- [x] Google Calendar data cached (5-minute TTL)
- [x] DST transitions handled correctly
- [x] Midnight-spanning windows handled correctly
- [ ] Fully booked days return empty (Phase 6 — requires Booking model)
