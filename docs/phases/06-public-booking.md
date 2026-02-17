# Phase 6 — Public Booking Page & Booking Creation

## Goal

Unauthenticated visitors view available time slots and book meetings. Double-booking prevented at the database level. Confirmations and cancellations handled via email with signed tokens.

## Tasks

- [ ] Create `Booking` model with migration (all fields from data model)
- [ ] Create `Contact` model with migration (all fields from data model)
- [ ] Unique index on `contacts(user_id, email)` for find-or-create
- [ ] Unique compound index on `bookings(schedule_link_id, start_time, status)` where status = "confirmed"
- [ ] Index on `bookings(schedule_link_id, start_time)` for fast lookups
- [ ] Index on `contacts(user_id, last_booked_at)` for sorted list
- [ ] Public booking page: `GET /book/:slug` (no auth, clean minimal layout, no sidebar)
- [ ] Display: meeting name, duration, location type, host name(s)
- [ ] Date picker: calendar month view (Stimulus controller)
- [ ] Visitor timezone detection via `Intl.DateTimeFormat().resolvedOptions().timeZone`
- [ ] Timezone override dropdown for visitor
- [ ] Past dates and beyond `max_future_days` grayed out
- [ ] Days with no availability grayed out
- [ ] On date selection: fetch available slots via Turbo Frame
- [ ] Time slot selection: display slots in visitor's timezone, each slot is a button
- [ ] On slot click: highlight and show booking form
- [ ] Booking form: invitee name, email, optional notes, confirm button, summary (date, time, duration, meeting name)
- [ ] `BookingsController#create` (public, no auth)
- [ ] Re-check slot availability in transaction before creating
- [ ] Create `Booking` record (times in UTC, store invitee timezone)
- [ ] Create/update `Contact` records: find_or_create by `(user_id, email)`, update name, `last_booked_at`, increment `total_bookings_count`, link via `contact_id`
- [ ] Create Google Calendar event for each connected member
- [ ] Send confirmation email to invitee
- [ ] Show confirmation page with booking details
- [ ] Cancellation: email includes link with signed token (`Rails.application.message_verifier`)
- [ ] `GET /bookings/:id/cancel?token=xxx` shows cancellation confirmation page
- [ ] `POST /bookings/:id/cancel` sets status to "cancelled", removes Google Calendar event
- [ ] Cancelled slots become available again

## TDD Cycles

### Cycle 1: Booking Model
- [ ] Test: `Booking` validates presence of `schedule_link`, `start_time`, `end_time`, `invitee_name`, `invitee_email`
- [ ] Test: `status` defaults to "confirmed"
- [ ] Test: `Booking belongs_to :schedule_link`
- [ ] Test: `Booking belongs_to :contact` (optional)
- [ ] Test: unique compound index prevents duplicate confirmed bookings at same time
- [ ] Implement: migration, model, validations

### Cycle 2: Contact Model
- [ ] Test: `Contact` validates presence of `user`, `name`, `email`
- [ ] Test: unique index on `(user_id, email)`
- [ ] Test: `Contact belongs_to :user`, `Contact has_many :bookings`
- [ ] Test: `total_bookings_count` defaults to 0
- [ ] Implement: migration, model, validations

### Cycle 3: Public Booking Page
- [ ] Test: `GET /book/:slug` renders without authentication
- [ ] Test: displays meeting name, duration, host names
- [ ] Test: uses clean layout (no sidebar)
- [ ] Test: invalid slug returns friendly 404
- [ ] Test: inactive schedule link returns friendly 404
- [ ] Implement: public `BookingPagesController#show`, public layout

### Cycle 4: Date Picker & Slot Selection
- [ ] Test: date picker renders calendar month view
- [ ] Test: selecting a date fetches slots via Turbo Frame
- [ ] Test: slots displayed in visitor's timezone
- [ ] Test: past dates not selectable
- [ ] Test: dates beyond `max_future_days` not selectable
- [ ] Implement: Stimulus date picker controller, slot display

### Cycle 5: Booking Form & Creation
- [ ] Test: submitting valid booking form creates Booking record
- [ ] Test: booking times stored in UTC
- [ ] Test: invitee timezone stored on booking
- [ ] Test: confirmation page shown after successful booking
- [ ] Test: invalid form (missing name/email) shows errors
- [ ] Implement: booking form, `BookingsController#create`

### Cycle 6: Double-Booking Prevention
- [ ] Test: concurrent booking attempts for same slot — only one succeeds
- [ ] Test: slot availability re-checked inside transaction
- [ ] Test: friendly error shown when slot taken
- [ ] Test: unique index raises on duplicate `(schedule_link_id, start_time, "confirmed")`
- [ ] Implement: transaction wrapping, rescue from index violation

### Cycle 7: Contact Find-or-Create
- [ ] Test: booking creates new Contact if email not seen before for that user
- [ ] Test: booking updates existing Contact if email already exists for that user
- [ ] Test: `last_booked_at` updated on booking
- [ ] Test: `total_bookings_count` incremented on booking
- [ ] Test: `contact_id` set on Booking record
- [ ] Test: Contact created for each member of the schedule link
- [ ] Implement: find-or-create logic in booking creation

### Cycle 8: Google Calendar Event Creation
- [ ] Test: booking creates Google Calendar event for connected members
- [ ] Test: `google_event_id` stored on Booking
- [ ] Test: no error when member not connected to Google Calendar
- [ ] Test: event includes correct title, times, description, location
- [ ] Implement: event creation in booking flow

### Cycle 9: Confirmation & Cancellation
- [ ] Test: confirmation email sent to invitee after booking
- [ ] Test: email contains cancellation link with signed token
- [ ] Test: `GET /bookings/:id/cancel?token=xxx` shows confirmation page
- [ ] Test: invalid/tampered token shows error
- [ ] Test: `POST /bookings/:id/cancel` sets status to "cancelled"
- [ ] Test: cancellation removes Google Calendar event
- [ ] Test: cancelled time slot becomes available again
- [ ] Test: cancelling already-cancelled booking shows appropriate message
- [ ] Implement: mailer, signed tokens, cancellation controller

## Key Files

```
app/models/booking.rb
app/models/contact.rb
app/controllers/booking_pages_controller.rb
app/controllers/bookings_controller.rb
app/controllers/booking_cancellations_controller.rb
app/views/booking_pages/show.html.erb
app/views/bookings/new.html.erb
app/views/bookings/confirmation.html.erb
app/views/booking_cancellations/show.html.erb
app/views/layouts/public.html.erb
app/mailers/booking_mailer.rb
app/javascript/controllers/date_picker_controller.js
db/migrate/*_create_bookings.rb
db/migrate/*_create_contacts.rb
config/routes.rb (updated)
test/models/booking_test.rb
test/models/contact_test.rb
test/controllers/bookings_controller_test.rb
test/controllers/booking_pages_controller_test.rb
test/system/public_booking_test.rb
```

## Acceptance Criteria

- [ ] Visitor can view schedule link page, browse dates, see times in their timezone
- [ ] Visitor can book a meeting with name and email
- [ ] Double-bookings prevented at database level
- [ ] Google Calendar events created for connected members
- [ ] Confirmation email sent to visitor
- [ ] Visitor can cancel via signed email link
- [ ] Cancelled slots become available again
- [ ] Friendly 404 for inactive or nonexistent slugs
