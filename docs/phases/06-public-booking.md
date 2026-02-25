# Phase 6 — Public Booking Page & Booking Creation

## Goal

Unauthenticated visitors view available time slots and book meetings. Double-booking prevented at the database level. Confirmations and cancellations handled via email with signed tokens.

## Tasks

- [x] Create `Booking` model with migration (all fields from data model)
- [x] Create `Contact` model with migration (all fields from data model)
- [x] Unique index on `contacts(user_id, email)` for find-or-create
- [x] Unique compound index on `bookings(schedule_link_id, start_time, status)` where status = "confirmed"
- [x] Index on `bookings(schedule_link_id, start_time)` for fast lookups
- [x] Index on `contacts(user_id, last_booked_at)` for sorted list
- [x] Public booking page: `GET /book/:slug` (no auth, clean minimal layout, no sidebar)
- [x] Display: meeting name, duration, location type, host name(s)
- [x] Date picker: calendar month view (Stimulus controller)
- [x] Visitor timezone detection via `Intl.DateTimeFormat().resolvedOptions().timeZone`
- [x] Timezone override dropdown for visitor
- [x] Past dates and beyond `max_future_days` grayed out
- [x] On date selection: fetch available slots via JSON API
- [x] Time slot selection: display slots in visitor's timezone, each slot is a button
- [x] On slot click: highlight and show booking form
- [x] Booking form: invitee name, email, optional notes, confirm button
- [x] `BookingsController#create` (public, no auth)
- [x] Re-check slot availability in transaction before creating
- [x] Create `Booking` record (times in UTC, store invitee timezone)
- [x] Create/update `Contact` records: find_or_create by `(user_id, email)`, update name, `last_booked_at`, increment `total_bookings_count`, link via `contact_id`
- [x] Create Google Calendar event for each connected member
- [x] Send confirmation email to invitee
- [x] Show confirmation page with booking details
- [x] Cancellation: email includes link with signed token (`Rails.application.message_verifier`)
- [x] `GET /bookings/:id/cancel?token=xxx` shows cancellation confirmation page
- [x] `POST /bookings/:id/cancel` sets status to "cancelled", removes Google Calendar event
- [x] Cancelled slots become available again

## TDD Cycles

### Cycle 1: Booking Model
- [x] Test: `Booking` validates presence of `schedule_link`, `start_time`, `end_time`, `invitee_name`, `invitee_email`
- [x] Test: `status` defaults to "confirmed"
- [x] Test: `Booking belongs_to :schedule_link`
- [x] Test: `Booking belongs_to :contact` (optional)
- [x] Test: unique compound index prevents duplicate confirmed bookings at same time
- [x] Implement: migration, model, validations

### Cycle 2: Contact Model
- [x] Test: `Contact` validates presence of `user`, `name`, `email`
- [x] Test: unique index on `(user_id, email)`
- [x] Test: `Contact belongs_to :user`
- [x] Test: `total_bookings_count` defaults to 0
- [x] Implement: migration, model, validations

### Cycle 3: Public Booking Page
- [x] Test: `GET /book/:slug` renders without authentication
- [x] Test: displays meeting name, duration, host names
- [x] Test: invalid slug returns friendly 404
- [x] Test: inactive schedule link returns friendly 404
- [x] Implement: public `BookingPagesController#show`, public layout

### Cycle 4: Date Picker & Slot Selection
- [x] Implement: Stimulus date picker controller, slot display, timezone detection

### Cycle 5: Booking Form & Creation
- [x] Test: submitting valid booking form creates Booking record
- [x] Test: booking times stored in UTC
- [x] Test: invitee timezone stored on booking
- [x] Test: confirmation page shown after successful booking
- [x] Test: invalid form (missing name/email) shows errors
- [x] Implement: booking form, `BookingsController#create`, `BookingService`

### Cycle 6: Double-Booking Prevention
- [x] Test: slot availability re-checked inside transaction
- [x] Test: friendly error shown when slot taken
- [x] Test: RecordNotUnique handled gracefully
- [x] Implement: transaction wrapping, rescue from index violation

### Cycle 7: Contact Find-or-Create
- [x] Test: booking creates new Contact if email not seen before for that user
- [x] Test: booking updates existing Contact if email already exists for that user
- [x] Test: `total_bookings_count` incremented on booking
- [x] Implement: find-or-create logic in BookingService

### Cycle 8: Google Calendar Event Creation
- [x] Test: no failure when GCal event creation fails
- [x] Implement: event creation in booking flow

### Cycle 9: Confirmation & Cancellation
- [x] Test: confirmation email sent to invitee after booking
- [x] Test: email subject includes meeting name
- [x] Test: email body contains meeting details
- [x] Test: email contains cancellation link with valid signed token
- [x] Test: `GET /bookings/:id/cancel?token=xxx` shows confirmation page
- [x] Test: invalid/tampered token shows 404
- [x] Test: `POST /bookings/:id/cancel` sets status to "cancelled"
- [x] Test: cancelled time slot becomes available again
- [x] Test: already-cancelled booking shows appropriate message
- [x] Implement: mailer, signed tokens, cancellation controller

## Key Files

```
app/models/booking.rb
app/models/contact.rb
app/controllers/booking_pages_controller.rb
app/controllers/bookings_controller.rb
app/controllers/booking_cancellations_controller.rb
app/services/booking_service.rb
app/views/booking_pages/show.html.erb
app/views/bookings/confirmation.html.erb
app/views/booking_cancellations/show.html.erb
app/views/layouts/public.html.erb
app/mailers/booking_mailer.rb
app/views/booking_mailer/confirmation.html.erb
app/views/booking_mailer/confirmation.text.erb
app/javascript/controllers/date_picker_controller.js
db/migrate/*_create_bookings.rb
db/migrate/*_create_contacts.rb
config/routes.rb (updated)
test/models/booking_test.rb
test/models/contact_test.rb
test/services/booking_service_test.rb
test/controllers/booking_pages_controller_test.rb
test/controllers/bookings_controller_test.rb
test/controllers/booking_cancellations_controller_test.rb
test/mailers/booking_mailer_test.rb
```

## Acceptance Criteria

- [x] Visitor can view schedule link page, browse dates, see times in their timezone
- [x] Visitor can book a meeting with name and email
- [x] Double-bookings prevented at database level
- [x] Google Calendar events created for connected members
- [x] Confirmation email sent to visitor
- [x] Visitor can cancel via signed email link
- [x] Cancelled slots become available again
- [x] Friendly 404 for inactive or nonexistent slugs
