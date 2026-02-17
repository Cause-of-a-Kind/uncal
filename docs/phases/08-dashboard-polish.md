# Phase 8 — Dashboard, Contacts, Polish & Production Readiness

## Goal

Complete the dashboard with booking stats, build the contacts management page, add error handling and rate limiting, configure booking pruning, and prepare for production deployment.

## Tasks

- [ ] Dashboard enhancements:
  - Upcoming bookings (next 7 days)
  - Recent bookings (last 7 days)
  - Quick stats: bookings this week, total schedule links
  - Quick link to create new schedule link
- [ ] Contacts list page (`GET /contacts`):
  - Sidebar nav item
  - List sorted by `last_booked_at` desc
  - Show: name, email, total bookings, last booked date
  - Search/filter by name or email
  - Click for booking history
  - Add/edit notes
  - Contacts persist after booking pruning
- [ ] Booking management for hosts (`GET /bookings`):
  - Filter by schedule link, date range, status
  - Cancel from host side
  - Show booking details
- [ ] Email setup for production:
  - Configure Action Mailer (Postmark, Resend, or SES)
  - Branded confirmation email template
  - Branded cancellation email template
  - Branded workflow email template
- [ ] Error handling & edge cases:
  - Friendly 404 for inactive/nonexistent slugs
  - Handle Google Calendar API failures gracefully
  - Rate limiting on public endpoints via `Rack::Attack`
  - CSRF protection (Rails built-in, verify configured)
- [ ] `BookingPruneJob`:
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
- [ ] Test: dashboard shows upcoming bookings (next 7 days)
- [ ] Test: dashboard shows recent bookings (last 7 days)
- [ ] Test: dashboard shows booking count for current week
- [ ] Test: dashboard shows total schedule links count
- [ ] Test: dashboard has link to create new schedule link
- [ ] Test: dashboard requires authentication
- [ ] Implement: update dashboard view and controller

### Cycle 2: Contacts List
- [ ] Test: contacts page lists contacts sorted by `last_booked_at` desc
- [ ] Test: each contact shows name, email, total bookings, last booked date
- [ ] Test: search by name filters results
- [ ] Test: search by email filters results
- [ ] Test: clicking contact shows their booking history
- [ ] Test: can add/edit notes on a contact
- [ ] Test: contacts page requires authentication
- [ ] Implement: `ContactsController`, views

### Cycle 3: Booking Management
- [ ] Test: bookings index shows all bookings for current user's schedule links
- [ ] Test: filter by schedule link works
- [ ] Test: filter by date range works
- [ ] Test: filter by status (confirmed/cancelled) works
- [ ] Test: host can cancel a booking
- [ ] Test: cancelling from host side sets status to "cancelled"
- [ ] Test: cancelling removes Google Calendar event
- [ ] Implement: `BookingsController` (authenticated), views

### Cycle 4: Error Handling
- [ ] Test: nonexistent slug returns 404 with friendly page
- [ ] Test: inactive schedule link returns 404 with friendly page
- [ ] Test: Google Calendar API failure doesn't break booking page
- [ ] Test: `Rack::Attack` throttles excessive requests to public endpoints
- [ ] Implement: error pages, `Rack::Attack` config, API failure handling

### Cycle 5: BookingPruneJob
- [ ] Test: job deletes bookings older than 90 days
- [ ] Test: job doesn't delete bookings newer than 90 days
- [ ] Test: job doesn't delete Contact records
- [ ] Test: job respects configurable retention period (ENV)
- [ ] Test: job logs count of pruned bookings
- [ ] Implement: `BookingPruneJob`, `config/recurring.yml`

### Cycle 6: Email Templates
- [ ] Test: confirmation email includes booking details (date, time, meeting name, location)
- [ ] Test: cancellation email includes booking details
- [ ] Test: emails render correctly (no broken layouts)
- [ ] Implement: branded mailer templates

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
app/controllers/bookings_controller.rb (authenticated actions)
app/views/dashboard/show.html.erb (updated)
app/views/contacts/index.html.erb
app/views/contacts/show.html.erb
app/views/bookings/index.html.erb
app/views/bookings/show.html.erb
app/jobs/booking_prune_job.rb
app/views/booking_mailer/ (templates)
config/recurring.yml
config/initializers/rack_attack.rb
app/views/errors/not_found.html.erb
Gemfile (rack-attack)
test/jobs/booking_prune_job_test.rb
test/controllers/contacts_controller_test.rb
test/controllers/bookings_controller_test.rb
test/system/dashboard_test.rb
```

## Acceptance Criteria

- [ ] Dashboard shows upcoming/recent bookings and quick stats
- [ ] Contacts page lists all contacts with search functionality
- [ ] Contact details show booking history and editable notes
- [ ] Hosts can view and cancel bookings from authenticated UI
- [ ] Friendly 404 pages for invalid/inactive schedule links
- [ ] Public endpoints rate-limited via `Rack::Attack`
- [ ] `BookingPruneJob` runs daily, keeps database clean, preserves contacts
- [ ] Email templates are branded and include all relevant details
- [ ] Production deployment configured with backups and persistent storage
