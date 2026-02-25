# Uncal — Project Plan

## Phase Status

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Authentication & User Foundation](phases/01-authentication.md) | `[x] Complete` |
| 2 | [Google Calendar Integration](phases/02-google-calendar.md) | `[x] Complete` |
| 3 | [Schedule Links (Core)](phases/03-schedule-links.md) | `[x] Complete` |
| 4 | [Availability Windows](phases/04-availability-windows.md) | `[x] Complete` |
| 5 | [Availability Calculation Engine](phases/05-availability-engine.md) | `[x] Complete` |
| 6 | [Public Booking Page & Booking Creation](phases/06-public-booking.md) | `[x] Complete` |
| 7 | [Email Workflows](phases/07-email-workflows.md) | `[ ] Pending` |
| 8 | [Dashboard, Polish & Production Readiness](phases/08-dashboard-polish.md) | `[ ] Pending` |

## Architecture Decisions

- **Rails 8 authentication generator** over Devise — simpler, fewer dependencies, built-in `Current.user`
- **Manual OAuth2 flow** for Google Calendar — not omniauth; simpler for a single provider
- **SQLite in production** — single-server deployment, separate files for primary/queue/cache/cable
- **Fixtures over factories** — Rails default, less magic, fast
- **Propshaft + importmap** — no Node.js build step
- **Hotwire (Turbo + Stimulus)** — no SPA framework, server-rendered with progressive enhancement
- **Shared ERB partials** in `app/views/ui/` — explicit locals, no raw CSS from callers
- **Solid Queue/Cache/Cable** — SQLite-backed, no Redis dependency
- **Kamal + Thruster** — Docker-based deployment with HTTP caching/compression

## Data Model Overview

### Models & Key Relationships

```
User
├── has_many :sessions
├── has_many :sent_invitations (as invited_by)
├── has_many :schedule_link_members
├── has_many :schedule_links (through schedule_link_members)
├── has_many :created_schedule_links (as created_by)
├── has_many :contacts
└── has_many :availability_windows

Invitation
└── belongs_to :invited_by (User)

ScheduleLink
├── belongs_to :created_by (User)
├── has_many :schedule_link_members
├── has_many :members (through schedule_link_members → User)
├── has_many :bookings
├── has_many :availability_windows
└── has_one :workflow

AvailabilityWindow
├── belongs_to :schedule_link
└── belongs_to :user

Booking
├── belongs_to :schedule_link
└── belongs_to :contact (optional)

Contact
├── belongs_to :user
└── has_many :bookings

Workflow
├── belongs_to :schedule_link
└── has_many :workflow_steps (ordered by position)

WorkflowStep
└── belongs_to :workflow
```

### Key Fields by Model

| Model | Notable Fields |
|-------|---------------|
| User | email_address, password_digest, name, timezone, google_calendar_token (encrypted), google_calendar_refresh_token (encrypted), google_calendar_connected |
| Invitation | invited_by_id, email, token (unique), accepted_at, expires_at (default 7 days) |
| ScheduleLink | slug (unique), name, meeting_duration_minutes, meeting_name, meeting_location_type, meeting_location_value, timezone, buffer_minutes, max_bookings_per_day, max_future_days, status |
| ScheduleLinkMember | schedule_link_id, user_id |
| AvailabilityWindow | schedule_link_id, user_id, day_of_week (0-6), start_time, end_time |
| Booking | schedule_link_id, contact_id, start_time (UTC), end_time (UTC), invitee_name, invitee_email, invitee_timezone, invitee_notes, status, google_event_id |
| Contact | user_id, name, email, notes, last_booked_at, total_bookings_count |
| Workflow | schedule_link_id, name, state |
| WorkflowStep | workflow_id, timing_direction, timing_minutes, email_subject, email_body, recipient_type, position |

## Non-Functional Notes

### Timezone Rules

- All datetimes stored in UTC
- Availability windows defined relative to the schedule link's timezone
- Visitor timezone detected via browser `Intl.DateTimeFormat().resolvedOptions().timeZone`
- `Time.zone` set per-request from `Current.user.timezone`
- DST handled via `ActiveSupport::TimeZone`

### Security

- No public registration — invite tokens only (7-day expiry, `SecureRandom.urlsafe_base64(32)`)
- Google OAuth tokens encrypted with `encrypts`
- Booking cancellation links use signed tokens (`Rails.application.message_verifier`)
- Rate limiting on public endpoints via `Rack::Attack`
- CSRF protection (Rails built-in)
- Double-booking prevention: transaction + unique compound index

### Performance Indices

- `bookings(schedule_link_id, start_time)` — booking lookups
- `availability_windows(schedule_link_id, user_id, day_of_week)` — window lookups
- `schedule_links(slug)` — public page loads
- `contacts(user_id, email)` — unique, find-or-create on booking
- `contacts(user_id, last_booked_at)` — sorted contacts list

### Caching

- Google Calendar busy times cached per user per date, 5-minute TTL (Solid Cache)
- Invalidated on new booking creation
