# Phase 2 — Google Calendar Integration

## Goal

Users connect their Google Calendar so the system can read existing events to determine true availability and create events on booking.

## Tasks

- [x] Add `google-apis-calendar_v3` gem (manual OAuth2 flow, not omniauth)
- [x] Create Google Cloud project, enable Calendar API
- [x] Store Google OAuth credentials in Rails credentials (`google.client_id`, `google.client_secret`)
- [x] Build OAuth connection flow controller (`GoogleCalendarController`)
- [x] `GET /google_calendar/connect` — redirects to Google OAuth consent screen
- [x] `GET /google_calendar/callback` — handles callback, stores encrypted tokens on User
- [x] `DELETE /google_calendar/disconnect` — clears tokens, sets `google_calendar_connected: false`
- [x] OAuth scopes: `calendar.readonly` and `calendar.events`
- [x] Encrypt tokens with `encrypts :google_calendar_token, :google_calendar_refresh_token`
- [x] Create `GoogleCalendarService` with methods:
  - `#events(start_date, end_date)`
  - `#busy_times(start_date, end_date)` — returns `[{start: DateTime, end: DateTime}]`
  - `#create_event(title:, start_time:, end_time:, description:, location:)`
- [x] Handle automatic token refresh when access token expires
- [x] Handle API errors gracefully (revoked access, rate limits, network errors)
- [x] Add connection status to settings page: "Connect Google Calendar" or "Connected — Disconnect"

## TDD Cycles

### Cycle 1: OAuth Credential Storage
- [x] Test: User model encrypts `google_calendar_token` and `google_calendar_refresh_token`
- [x] Test: User has `google_calendar_connected` boolean (default: false)
- [x] Test: User has `google_calendar_token_expires_at` datetime
- [x] Implement: add `encrypts` declarations to User model (fields already exist from Phase 1 migration)

### Cycle 2: OAuth Controller Flow
- [x] Test: `GET /google_calendar/connect` redirects to Google OAuth URL with correct scopes
- [x] Test: `GET /google_calendar/connect` requires authentication
- [x] Test: `GET /google_calendar/callback` stores tokens on current user
- [x] Test: `GET /google_calendar/callback` sets `google_calendar_connected: true`
- [x] Test: `GET /google_calendar/callback` redirects to settings with success flash
- [x] Test: `DELETE /google_calendar/disconnect` clears all token fields
- [x] Test: `DELETE /google_calendar/disconnect` sets `google_calendar_connected: false`
- [x] Implement: `GoogleCalendarController` with connect, callback, disconnect actions

### Cycle 3: GoogleCalendarService (with Mocks)
- [x] Test: `#busy_times` returns array of `{start:, end:}` hashes for busy periods
- [x] Test: `#busy_times` handles empty calendar (returns empty array)
- [x] Test: `#busy_times` converts API response times to UTC
- [x] Test: `#create_event` calls Google Calendar API with correct parameters
- [x] Test: `#create_event` returns the created event's ID
- [x] Test: service raises descriptive error when user not connected
- [x] Test: service handles API errors (returns empty array or raises specific exception)
- [x] Implement: `app/services/google_calendar_service.rb`

### Cycle 4: Token Refresh
- [x] Test: service refreshes token when `google_calendar_token_expires_at` is past
- [x] Test: refreshed token is saved to user record
- [x] Test: service works transparently after token refresh
- [x] Test: service handles refresh failure (revoked access) gracefully
- [x] Implement: token refresh logic in `GoogleCalendarService`

## Key Files

```
app/services/google_calendar_service.rb
app/controllers/google_calendar_controller.rb
app/views/settings/edit.html.erb (updated)
config/routes.rb (updated)
config/credentials.yml.enc (google.client_id, google.client_secret)
Gemfile (google-apis-calendar_v3)
test/services/google_calendar_service_test.rb
test/controllers/google_calendar_controller_test.rb
```

## Acceptance Criteria

- [x] User can connect Google Calendar from settings page
- [x] User can disconnect Google Calendar from settings page
- [x] Tokens encrypted at rest (not readable in database)
- [x] Token refresh works transparently (user doesn't need to re-authorize)
- [x] `GoogleCalendarService#busy_times` returns accurate busy periods
- [x] `GoogleCalendarService#create_event` creates events on connected calendar
- [x] Connection status visible in settings UI
- [x] Graceful handling when Google API is unavailable
