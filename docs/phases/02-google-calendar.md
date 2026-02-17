# Phase 2 — Google Calendar Integration

## Goal

Users connect their Google Calendar so the system can read existing events to determine true availability and create events on booking.

## Tasks

- [ ] Add `google-apis-calendar_v3` gem (manual OAuth2 flow, not omniauth)
- [ ] Create Google Cloud project, enable Calendar API
- [ ] Store Google OAuth credentials in Rails credentials (`google.client_id`, `google.client_secret`)
- [ ] Build OAuth connection flow controller (`GoogleCalendarController`)
- [ ] `GET /google_calendar/connect` — redirects to Google OAuth consent screen
- [ ] `GET /google_calendar/callback` — handles callback, stores encrypted tokens on User
- [ ] `DELETE /google_calendar/disconnect` — clears tokens, sets `google_calendar_connected: false`
- [ ] OAuth scopes: `calendar.readonly` and `calendar.events`
- [ ] Encrypt tokens with `encrypts :google_calendar_token, :google_calendar_refresh_token`
- [ ] Create `GoogleCalendarService` with methods:
  - `#events(start_date, end_date)`
  - `#busy_times(start_date, end_date)` — returns `[{start: DateTime, end: DateTime}]`
  - `#create_event(title:, start_time:, end_time:, description:, location:)`
- [ ] Handle automatic token refresh when access token expires
- [ ] Handle API errors gracefully (revoked access, rate limits, network errors)
- [ ] Add connection status to settings page: "Connect Google Calendar" or "Connected — Disconnect"

## TDD Cycles

### Cycle 1: OAuth Credential Storage
- [ ] Test: User model encrypts `google_calendar_token` and `google_calendar_refresh_token`
- [ ] Test: User has `google_calendar_connected` boolean (default: false)
- [ ] Test: User has `google_calendar_token_expires_at` datetime
- [ ] Implement: add `encrypts` declarations to User model (fields already exist from Phase 1 migration)

### Cycle 2: OAuth Controller Flow
- [ ] Test: `GET /google_calendar/connect` redirects to Google OAuth URL with correct scopes
- [ ] Test: `GET /google_calendar/connect` requires authentication
- [ ] Test: `GET /google_calendar/callback` stores tokens on current user
- [ ] Test: `GET /google_calendar/callback` sets `google_calendar_connected: true`
- [ ] Test: `GET /google_calendar/callback` redirects to settings with success flash
- [ ] Test: `DELETE /google_calendar/disconnect` clears all token fields
- [ ] Test: `DELETE /google_calendar/disconnect` sets `google_calendar_connected: false`
- [ ] Implement: `GoogleCalendarController` with connect, callback, disconnect actions

### Cycle 3: GoogleCalendarService (with Mocks)
- [ ] Test: `#busy_times` returns array of `{start:, end:}` hashes for busy periods
- [ ] Test: `#busy_times` handles empty calendar (returns empty array)
- [ ] Test: `#busy_times` converts API response times to UTC
- [ ] Test: `#create_event` calls Google Calendar API with correct parameters
- [ ] Test: `#create_event` returns the created event's ID
- [ ] Test: service raises descriptive error when user not connected
- [ ] Test: service handles API errors (returns empty array or raises specific exception)
- [ ] Implement: `app/services/google_calendar_service.rb`

### Cycle 4: Token Refresh
- [ ] Test: service refreshes token when `google_calendar_token_expires_at` is past
- [ ] Test: refreshed token is saved to user record
- [ ] Test: service works transparently after token refresh
- [ ] Test: service handles refresh failure (revoked access) gracefully
- [ ] Implement: token refresh logic in `GoogleCalendarService`

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

- [ ] User can connect Google Calendar from settings page
- [ ] User can disconnect Google Calendar from settings page
- [ ] Tokens encrypted at rest (not readable in database)
- [ ] Token refresh works transparently (user doesn't need to re-authorize)
- [ ] `GoogleCalendarService#busy_times` returns accurate busy periods
- [ ] `GoogleCalendarService#create_event` creates events on connected calendar
- [ ] Connection status visible in settings UI
- [ ] Graceful handling when Google API is unavailable
