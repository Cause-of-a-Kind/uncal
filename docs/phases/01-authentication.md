# Phase 1 — Authentication & User Foundation

## Goal

Seed the first user via rake task, enable invite-only registration, build authenticated dashboard with sidebar navigation and timezone support.

## Tasks

- [ ] Install and configure Tailwind CSS with clean base layout (sidebar nav + main content area)
- [ ] Generate authentication: `rails g authentication` — creates User, Session, auth concerns
- [ ] Add `name`, `timezone` fields to User before running migration
- [ ] Add `google_calendar_*` fields to User (all nullable, for Phase 2)
- [ ] Remove public registration routes — no `/sign_up` or `/register`
- [ ] Create `lib/tasks/setup.rake` with `setup:admin` task (prompts or accepts ENV vars, idempotent)
- [ ] Create Invitation model with migration (`invited_by_id`, `email`, `token`, `accepted_at`, `expires_at`)
- [ ] Implement token generation (`SecureRandom.urlsafe_base64(32)`) and 7-day default expiry
- [ ] Add scopes: `pending`, `accepted`, `expired`
- [ ] Build InvitationsController (authenticated): index, new/create, destroy
- [ ] Add "Invite Team Member" to sidebar/settings
- [ ] Build invite acceptance flow: `GET /invitations/:token/accept` (public)
- [ ] Registration form on acceptance: name, password, password confirmation; email pre-filled and read-only
- [ ] Handle invalid/expired tokens with friendly error page
- [ ] Create `InvitationMailer#invite(invitation)` — queued via Solid Queue
- [ ] Build dashboard at `/dashboard` with sidebar navigation
- [ ] Sidebar nav items: Dashboard, Schedule Links, Bookings, Contacts, Settings
- [ ] Build settings page: edit name, email, timezone
- [ ] Team section in settings: user list + pending invitations
- [ ] Add timezone support: `ActiveSupport::TimeZone` dropdown, store IANA string
- [ ] Set `Time.zone` from current user via `around_action` in `ApplicationController`
- [ ] Create UI kit skeleton in `app/views/ui/`: `_button`, `_card`, `_flash`, `_form_field`, `_badge`, `_empty_state`, `_modal`

## TDD Cycles

### Cycle 1: Tailwind & Layout
- [ ] System test: visiting root path renders a page with sidebar navigation
- [ ] Verify Tailwind utility classes render correctly
- [ ] Implement: install Tailwind, create application layout with sidebar

### Cycle 2: Authentication Generator
- [ ] Test: `User` model exists with `email_address`, `password_digest`, `name`, `timezone`
- [ ] Test: `User` validates presence of `email_address`
- [ ] Test: `User` validates uniqueness of `email_address`
- [ ] Test: unauthenticated request to `/dashboard` redirects to `/session/new`
- [ ] Test: valid login creates session and redirects to dashboard
- [ ] Test: `GET /sign_up` returns 404
- [ ] Implement: run `rails g authentication`, add fields, remove registration route

### Cycle 3: Seed Rake Task
- [ ] Test: `setup:admin` creates a user with given email/name/password
- [ ] Test: `setup:admin` is idempotent — running twice with same email updates existing user
- [ ] Test: created user can log in
- [ ] Implement: `lib/tasks/setup.rake`

### Cycle 4: Invitation Model
- [ ] Test: `Invitation` requires `email` and `invited_by`
- [ ] Test: token auto-generated on create (32-byte `urlsafe_base64`)
- [ ] Test: `expires_at` defaults to 7 days from now
- [ ] Test: `pending` scope returns invitations not accepted and not expired
- [ ] Test: `accepted` scope returns invitations with `accepted_at` set
- [ ] Test: `expired` scope returns invitations past `expires_at`
- [ ] Test: `Invitation` belongs_to `invited_by` (User)
- [ ] Implement: migration, model, validations, callbacks, scopes

### Cycle 5: Invitation Flow (Integration)
- [ ] Test: authenticated user can create invitation (POST `/invitations`)
- [ ] Test: creating invitation sends email via `InvitationMailer`
- [ ] Test: unauthenticated user cannot access invitation management
- [ ] Test: `GET /invitations/:token/accept` with valid token shows registration form
- [ ] Test: `GET /invitations/:token/accept` with expired token shows error
- [ ] Test: `GET /invitations/:token/accept` with used token shows error
- [ ] Test: submitting registration form creates user, sets `accepted_at`, logs in, redirects to dashboard
- [ ] Test: registration form pre-fills email (read-only)
- [ ] Implement: `InvitationsController`, `InvitationAcceptancesController`, mailer

### Cycle 6: Dashboard & Navigation (System Tests)
- [ ] Test: authenticated user sees sidebar with all nav items
- [ ] Test: active nav item highlighted on current page
- [ ] Test: settings page shows name, email, timezone fields
- [ ] Test: settings page shows team list and pending invitations
- [ ] Test: updating settings persists changes
- [ ] Implement: dashboard view, sidebar partial, settings page

### Cycle 7: Timezone Support
- [ ] Test: user can update timezone in settings
- [ ] Test: `Time.zone` is set to user's timezone during request
- [ ] Test: timezone select shows `ActiveSupport::TimeZone` options
- [ ] Test: default timezone is "UTC"
- [ ] Implement: `around_action` in `ApplicationController`, timezone form field

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

- [ ] No public registration page — `/sign_up` returns 404
- [ ] First user created via `bin/rails setup:admin`
- [ ] Authenticated users can send email invitations
- [ ] Invitees receive email with unique, time-limited link
- [ ] Invitees can set name and password; email locked to invitation
- [ ] Expired/used invite tokens show clear error
- [ ] After accepting, new user logged in and can use app
- [ ] All authenticated pages redirect to login if not signed in
