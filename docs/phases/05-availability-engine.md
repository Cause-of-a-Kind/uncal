# Phase 5 — Availability Calculation Engine

## Goal

Build the core engine that computes available time slots by intersecting all members' availability, subtracting busy times, and respecting all scheduling constraints.

## Tasks

- [ ] Create `AvailabilityCalculator` service: `AvailabilityCalculator.new(schedule_link, date)`
- [ ] Returns array of `{ start_time: DateTime, end_time: DateTime }` in UTC
- [ ] Implement the 10-step slot generation algorithm (see below)
- [ ] Create `TimeSlotHelper` utility with range operations
- [ ] Add caching layer for Google Calendar busy times (5-minute TTL via Solid Cache)
- [ ] Invalidate cache on new booking creation
- [ ] Create public availability API endpoint (no auth required)
- [ ] `GET /book/:slug/availability?date=2025-03-15&timezone=America/New_York`
- [ ] Returns JSON array of available slots in requester's timezone

## 10-Step Slot Generation Algorithm

For a given `schedule_link` and `date`:

1. **Determine day_of_week** for the date in the schedule link's timezone
2. **Reject past dates** — if date is in the past, return empty
3. **Reject beyond max_future_days** — if date is beyond `max_future_days` from today, return empty
4. **For each member** of the schedule link:
   - (a) Get their `AvailabilityWindow` records for that `day_of_week` on this link
   - (b) Convert window times to UTC for the specific date (e.g., "09:00 America/New_York on 2025-03-15" → UTC datetime)
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
- [ ] Test: `intersect_ranges` with two overlapping ranges returns overlap
- [ ] Test: `intersect_ranges` with non-overlapping ranges returns empty
- [ ] Test: `intersect_ranges` with multiple ranges on each side
- [ ] Test: `intersect_ranges` where one range fully contains the other
- [ ] Test: `subtract_ranges` removes a middle section (splits base range)
- [ ] Test: `subtract_ranges` removes start of base range
- [ ] Test: `subtract_ranges` removes end of base range
- [ ] Test: `subtract_ranges` with no overlap returns base unchanged
- [ ] Test: `subtract_ranges` with complete overlap returns empty
- [ ] Test: `subtract_ranges` with multiple subtractions
- [ ] Test: `split_into_slots` divides a range into 30-minute slots
- [ ] Test: `split_into_slots` starts on 15-minute boundaries
- [ ] Test: `split_into_slots` drops partial slots that don't fit
- [ ] Test: `split_into_slots` with custom interval (e.g., 15-minute)
- [ ] Test: `split_into_slots` with multiple non-contiguous ranges
- [ ] Implement: `app/services/time_slot_helper.rb`

### Cycle 2: AvailabilityCalculator — Single Member
- [ ] Test: returns available slots for a member with one availability window
- [ ] Test: returns empty for a past date
- [ ] Test: returns empty for a date beyond `max_future_days`
- [ ] Test: subtracts Google Calendar busy times from availability
- [ ] Test: returns empty when member has no windows for that day
- [ ] Test: handles member with multiple windows on same day
- [ ] Test: converts availability window times to UTC correctly
- [ ] Implement: basic `AvailabilityCalculator` for single member

### Cycle 3: AvailabilityCalculator — Multi-Member & Constraints
- [ ] Test: intersects availability across two members (only mutual free times)
- [ ] Test: intersects across three members
- [ ] Test: returns empty when members have no overlapping availability
- [ ] Test: subtracts existing confirmed bookings from availability
- [ ] Test: booking subtraction includes buffer minutes
- [ ] Test: returns empty when `max_bookings_per_day` reached
- [ ] Test: cancelled bookings don't count against availability
- [ ] Implement: multi-member intersection, booking/buffer subtraction

### Cycle 4: DST & Edge Cases
- [ ] Test: correct slot generation across DST spring-forward transition
- [ ] Test: correct slot generation across DST fall-back transition
- [ ] Test: midnight-spanning availability window (e.g., 22:00-02:00)
- [ ] Test: fully booked day returns empty
- [ ] Test: today's date only shows future slots (not past times today)
- [ ] Implement: DST handling, edge case coverage

### Cycle 5: Caching Layer
- [ ] Test: Google Calendar busy times cached with 5-minute TTL
- [ ] Test: second call within TTL uses cached data (no API call)
- [ ] Test: cache invalidated when new booking created
- [ ] Test: cache miss triggers API call and stores result
- [ ] Implement: Solid Cache integration in `GoogleCalendarService` or `AvailabilityCalculator`

### Cycle 6: Public Availability API
- [ ] Test: `GET /book/:slug/availability?date=...&timezone=...` returns JSON
- [ ] Test: response contains array of `{start_time, end_time}` in requester's timezone
- [ ] Test: no authentication required
- [ ] Test: invalid slug returns 404
- [ ] Test: missing date param returns 400
- [ ] Test: inactive schedule link returns 404
- [ ] Implement: `AvailabilityController`, route

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

- [ ] Correctly computes availability across multiple members
- [ ] Respects all constraints: availability windows, Google Calendar busy times, existing bookings, buffer, max per day, max future days, no past dates
- [ ] Slots split on 15-minute boundaries
- [ ] All times stored in UTC, converted for display
- [ ] Availability endpoint returns slots in requester's timezone
- [ ] Google Calendar data cached (5-minute TTL)
- [ ] DST transitions handled correctly
- [ ] Midnight-spanning windows handled correctly
- [ ] Fully booked days return empty
