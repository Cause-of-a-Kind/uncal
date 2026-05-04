# Uncal — Self-Hosted Calendar Booking System

Invite-only scheduling app (like Calendly) built for small teams. No public registration — first user seeded via rake task, all others join via email invitation.

## Tech Stack

- **Framework:** Rails 8.1.2, Ruby 3.4.8
- **Database:** SQLite3 (production + development), WAL mode enabled
- **Asset pipeline:** Propshaft
- **JavaScript:** importmap-rails (no Node/webpack)
- **Frontend:** Hotwire (Turbo + Stimulus), Tailwind CSS
- **Background jobs:** Solid Queue (SQLite-backed)
- **Caching:** Solid Cache (SQLite-backed)
- **WebSockets:** Solid Cable (SQLite-backed)
- **Deployment:** Kamal + Thruster
- **Testing:** Minitest (Rails default), Capybara + Selenium for system tests
- **Auth:** Rails 8 authentication generator (`rails g authentication`)

## Key Commands

```sh
bin/rails test                  # Run all tests
bin/rails test:system           # Run system tests
bin/rails server                # Start dev server
bin/rails db:migrate            # Run migrations
bin/rails setup:admin           # Seed first admin user
```

## Code Conventions

### TDD-First

Every feature starts with a failing test derived from acceptance criteria. Write the test, watch it fail, implement the minimum code to pass, then refactor.

### Shared UI Partials

Reusable components live in `app/views/ui/`. Render with explicit locals — never pass raw CSS from callers.

Components: `_button`, `_card`, `_flash`, `_form_field`, `_badge`, `_empty_state`, `_modal`

### Timezone Handling

- **Store UTC** in the database, always
- **Display** in the user's timezone (or visitor's detected timezone on public pages)
- Set `Time.zone` via `around_action` in `ApplicationController` from `Current.user.timezone`
- Use `ActiveSupport::TimeZone` for conversions — handles DST correctly
- Schedule link availability windows are defined relative to the link's timezone

### Authentication

- Rails 8 generator provides `User`, `Session`, `Current` (CurrentAttributes)
- `Current.user` available everywhere via `CurrentAttributes`
- No public registration — `/sign_up` returns 404
- First user created via `bin/rails setup:admin`
- Subsequent users join via `Invitation` tokens (7-day expiry)

### Testing

- **Fixtures over factories** — use Rails fixtures with `fixtures :all`
- Model tests in `test/models/`
- Integration tests in `test/integration/`
- System tests in `test/system/` (Capybara + Selenium)
- Service/utility tests in `test/services/`

### Database

- SQLite for all environments (primary, queue, cache, cable are separate files)
- Google Calendar tokens encrypted via `encrypts` attribute
- Key indices defined in migrations for performance

## Project Plan

See `docs/PLAN.md` for the 8-phase implementation plan with status tracking.
