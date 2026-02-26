# Phase 8 — Dashboard, Contacts, Polish & Production Readiness

## Status: COMPLETE

## Goal

Complete the dashboard with booking stats, build the contacts management page, add error handling and rate limiting, configure booking pruning, and prepare for production deployment.

## Tasks

- [x] Dashboard enhancements:
  - Upcoming bookings (next 7 days)
  - Recent bookings (last 7 days)
  - Quick stats: bookings this week, total schedule links
  - Quick link to create new schedule link
- [x] Contacts list page (`GET /contacts`):
  - Sidebar nav item
  - List sorted by `last_booked_at` desc
  - Show: name, email, total bookings, last booked date
  - Search/filter by name or email
  - Click for booking history
  - Add/edit notes
  - Contacts persist after booking pruning
- [x] Booking management for hosts (`GET /bookings`):
  - Filter by schedule link, date range, status
  - Cancel from host side
  - Show booking details
- [x] Email setup for production:
  - Branded confirmation email template
  - Branded cancellation email template
  - Branded mailer layout with Uncal header/footer
- [x] Error handling & edge cases:
  - Friendly 404 for inactive/nonexistent slugs
  - Handle Google Calendar API failures gracefully
  - Rate limiting on public endpoints via `Rack::Attack`
  - CSRF protection (Rails built-in, verify configured)
- [x] `BookingPruneJob`:
  - Runs daily at 3 AM via Solid Queue recurring
  - Deletes bookings older than 90 days (configurable via ENV)
  - Only deletes bookings, Contact records retained
  - Contact denormalized fields (`total_bookings_count`, `last_booked_at`) unaffected
  - Logs pruned count
  - Config in `config/recurring.yml`
- [ ] Production deployment:
  - Single-server (DigitalOcean/Hetzner VPS)
  - SQLite with separate files for primary/queue/cache/cable
  - Persistent `storage/` directory across deploys
  - Solid Queue worker process
  - Automated daily backups (Litestream to S3 or cron with `sqlite3 .backup`)
  - WAL mode (Rails 8 default)

## TDD Cycles

### Cycle 1: Dashboard
- [x] Test: dashboard shows upcoming bookings (next 7 days)
- [x] Test: dashboard shows recent bookings (last 7 days)
- [x] Test: dashboard shows booking count for current week
- [x] Test: dashboard shows total schedule links count
- [x] Test: dashboard has link to create new schedule link
- [x] Test: dashboard requires authentication
- [x] Implement: update dashboard view and controller

### Cycle 2: Contacts List
- [x] Test: contacts page lists contacts sorted by `last_booked_at` desc
- [x] Test: each contact shows name, email, total bookings, last booked date
- [x] Test: search by name filters results
- [x] Test: search by email filters results
- [x] Test: clicking contact shows their booking history
- [x] Test: can add/edit notes on a contact
- [x] Test: contacts page requires authentication
- [x] Implement: `ContactsController`, views

### Cycle 3: Booking Management
- [x] Test: bookings index shows all bookings for current user's schedule links
- [x] Test: filter by schedule link works
- [x] Test: filter by date range works
- [x] Test: filter by status (confirmed/cancelled) works
- [x] Test: host can cancel a booking
- [x] Test: cancelling from host side sets status to "cancelled"
- [x] Test: cancelling removes Google Calendar event
- [x] Implement: `BookingsController` (authenticated), views

### Cycle 4: Error Handling
- [x] Test: nonexistent slug returns 404 with friendly page
- [x] Test: inactive schedule link returns 404 with friendly page
- [x] Test: Google Calendar API failure doesn't break booking page
- [x] Test: `Rack::Attack` throttles excessive requests to public endpoints
- [x] Implement: error pages, `Rack::Attack` config, API failure handling

### Cycle 5: BookingPruneJob
- [x] Test: job deletes bookings older than 90 days
- [x] Test: job doesn't delete bookings newer than 90 days
- [x] Test: job doesn't delete Contact records
- [x] Test: job respects configurable retention period (ENV)
- [x] Test: job logs count of pruned bookings
- [x] Implement: `BookingPruneJob`, `config/recurring.yml`

### Cycle 6: Email Templates
- [x] Test: confirmation email includes booking details (date, time, meeting name, location)
- [x] Test: cancellation email includes booking details
- [x] Test: emails render correctly (no broken layouts)
- [x] Implement: branded mailer templates

### Cycle 7: Production Config
- [ ] Test: database config has separate files for primary/queue/cache/cable
- [ ] Test: recurring jobs configured in `config/recurring.yml`
- [ ] Verify: Kamal deploy config (`config/deploy.yml`)
- [ ] Verify: Litestream or backup cron configured
- [ ] Implement: production configs, backup setup

## Key Files

```
app/controllers/dashboard_controller.rb (updated)
app/controllers/contacts_controller.rb
app/controllers/admin/bookings_controller.rb (updated)
app/views/dashboard/show.html.erb (updated)
app/views/contacts/index.html.erb
app/views/contacts/show.html.erb
app/views/admin/bookings/index.html.erb (updated)
app/views/admin/bookings/show.html.erb (updated)
app/jobs/booking_prune_job.rb
app/views/booking_mailer/ (templates)
app/views/layouts/mailer.html.erb (branded)
config/recurring.yml
config/initializers/rack_attack.rb
app/views/booking_pages/not_found.html.erb
public/429.html
Gemfile (rack-attack, letter_opener)
test/jobs/booking_prune_job_test.rb
test/controllers/contacts_controller_test.rb
test/controllers/admin/bookings_controller_test.rb
test/controllers/dashboard_controller_test.rb
test/integration/error_handling_test.rb
test/mailers/booking_mailer_test.rb
```

## Acceptance Criteria

- [x] Dashboard shows upcoming/recent bookings and quick stats
- [x] Contacts page lists all contacts with search functionality
- [x] Contact details show booking history and editable notes
- [x] Hosts can view and cancel bookings from authenticated UI
- [x] Friendly 404 pages for invalid/inactive schedule links
- [x] Public endpoints rate-limited via `Rack::Attack`
- [x] `BookingPruneJob` runs daily, keeps database clean, preserves contacts
- [x] Email templates are branded and include all relevant details
- [ ] Production deployment configured with backups and persistent storage
