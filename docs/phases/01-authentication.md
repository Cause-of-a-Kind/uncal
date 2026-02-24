# Phase 1 — Authentication & User Foundation

## Goal

Seed the first user via rake task, enable invite-only registration, build authenticated dashboard with sidebar navigation and timezone support.

## Tasks

- [x] Install and configure Tailwind CSS with clean base layout (sidebar nav + main content area)
- [x] Generate authentication: `rails g authentication` — creates User, Session, auth concerns
- [x] Add `name`, `timezone` fields to User before running migration
- [x] Add `google_calendar_*` fields to User (all nullable, for Phase 2)
- [x] Remove public registration routes — no `/sign_up` or `/register`
- [x] Create `lib/tasks/setup.rake` with `setup:admin` task (prompts or accepts ENV vars, idempotent)
- [x] Create Invitation model with migration (`invited_by_id`, `email`, `token`, `accepted_at`, `expires_at`)
- [x] Implement token generation (`SecureRandom.urlsafe_base64(32)`) and 7-day default expiry
- [x] Add scopes: `pending`, `accepted`, `expired`
- [x] Build InvitationsController (authenticated): index, new/create, destroy
- [x] Add "Invite Team Member" to sidebar/settings
- [x] Build invite acceptance flow: `GET /invitations/:token/accept` (public)
- [x] Registration form on acceptance: name, password, password confirmation; email pre-filled and read-only
- [x] Handle invalid/expired tokens with friendly error page
- [x] Create `InvitationMailer#invite(invitation)` — queued via Solid Queue
- [x] Build dashboard at `/dashboard` with sidebar navigation
- [x] Sidebar nav items: Dashboard, Schedule Links, Bookings, Contacts, Settings
- [x] Build settings page: edit name, email, timezone
- [x] Team section in settings: user list + pending invitations
- [x] Add timezone support: `ActiveSupport::TimeZone` dropdown, store IANA string
- [x] Set `Time.zone` from current user via `around_action` in `ApplicationController`
- [x] Create UI kit skeleton in `app/views/ui/`: `_button`, `_card`, `_flash`, `_form_field`, `_badge`, `_empty_state`, `_modal`

## TDD Cycles

### Cycle 1: Tailwind & Layout
- [x] System test: visiting root path renders a page with sidebar navigation
- [x] Verify Tailwind utility classes render correctly
- [x] Implement: install Tailwind, create application layout with sidebar

### Cycle 2: Authentication Generator
- [x] Test: `User` model exists with `email_address`, `password_digest`, `name`, `timezone`
- [x] Test: `User` validates presence of `email_address`
- [x] Test: `User` validates uniqueness of `email_address`
- [x] Test: unauthenticated request to `/dashboard` redirects to `/session/new`
- [x] Test: valid login creates session and redirects to dashboard
- [x] Test: `GET /sign_up` returns 404
- [x] Implement: run `rails g authentication`, add fields, remove registration route

### Cycle 3: Seed Rake Task
- [x] Test: `setup:admin` creates a user with given email/name/password
- [x] Test: `setup:admin` is idempotent — running twice with same email updates existing user
- [x] Test: created user can log in
- [x] Implement: `lib/tasks/setup.rake`

### Cycle 4: Invitation Model
- [x] Test: `Invitation` requires `email` and `invited_by`
- [x] Test: token auto-generated on create (32-byte `urlsafe_base64`)
- [x] Test: `expires_at` defaults to 7 days from now
- [x] Test: `pending` scope returns invitations not accepted and not expired
- [x] Test: `accepted` scope returns invitations with `accepted_at` set
- [x] Test: `expired` scope returns invitations past `expires_at`
- [x] Test: `Invitation` belongs_to `invited_by` (User)
- [x] Implement: migration, model, validations, callbacks, scopes

### Cycle 5: Invitation Flow (Integration)
- [x] Test: authenticated user can create invitation (POST `/invitations`)
- [x] Test: creating invitation sends email via `InvitationMailer`
- [x] Test: unauthenticated user cannot access invitation management
- [x] Test: `GET /invitations/:token/accept` with valid token shows registration form
- [x] Test: `GET /invitations/:token/accept` with expired token shows error
- [x] Test: `GET /invitations/:token/accept` with used token shows error
- [x] Test: submitting registration form creates user, sets `accepted_at`, logs in, redirects to dashboard
- [x] Test: registration form pre-fills email (read-only)
- [x] Implement: `InvitationsController`, `InvitationAcceptancesController`, mailer

### Cycle 6: Dashboard & Navigation (System Tests)
- [x] Test: authenticated user sees sidebar with all nav items
- [x] Test: active nav item highlighted on current page
- [x] Test: settings page shows name, email, timezone fields
- [x] Test: settings page shows team list and pending invitations
- [x] Test: updating settings persists changes
- [x] Implement: dashboard view, sidebar partial, settings page

### Cycle 7: Timezone Support
- [x] Test: user can update timezone in settings
- [x] Test: `Time.zone` is set to user's timezone during request
- [x] Test: timezone select shows `ActiveSupport::TimeZone` options
- [x] Test: default timezone is "UTC"
- [x] Implement: `around_action` in `ApplicationController`, timezone form field

## Key Files

```
lib/tasks/setup.rake
app/models/user.rb
app/models/session.rb
app/models/invitation.rb
app/models/current.rb
app/controllers/application_controller.rb
app/controllers/sessions_controller.rb
app/controllers/invitations_controller.rb
app/controllers/invitation_acceptances_controller.rb
app/controllers/dashboard_controller.rb
app/controllers/settings_controller.rb
app/mailers/invitation_mailer.rb
app/views/layouts/application.html.erb
app/views/layouts/_sidebar.html.erb
app/views/sessions/new.html.erb
app/views/invitations/index.html.erb
app/views/invitations/new.html.erb
app/views/invitation_acceptances/show.html.erb
app/views/dashboard/show.html.erb
app/views/settings/edit.html.erb
app/views/ui/_button.html.erb
app/views/ui/_card.html.erb
app/views/ui/_flash.html.erb
app/views/ui/_form_field.html.erb
app/views/ui/_badge.html.erb
app/views/ui/_empty_state.html.erb
app/views/ui/_modal.html.erb
config/routes.rb
```

## Acceptance Criteria

- [x] No public registration page — `/sign_up` returns 404
- [x] First user created via `bin/rails setup:admin`
- [x] Authenticated users can send email invitations
- [x] Invitees receive email with unique, time-limited link
- [x] Invitees can set name and password; email locked to invitation
- [x] Expired/used invite tokens show clear error
- [x] After accepting, new user logged in and can use app
- [x] All authenticated pages redirect to login if not signed in
