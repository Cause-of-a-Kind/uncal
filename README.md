# Uncal

Self-hosted calendar booking for small teams. Like Calendly, but you own it.

Built with Rails 8, SQLite, and Hotwire. No Redis, no Node.js, no external services required.

## Features

- **Invite-only teams** — No public sign-up. First user seeded via rake task, everyone else joins by email invitation.
- **Schedule links** — Create shareable booking pages with custom slugs, durations, locations, and team members.
- **Availability windows** — Define recurring weekly availability per link. The engine intersects all members' free time.
- **Google Calendar sync** — Reads busy times to avoid conflicts, creates events on booking.
- **Automated email workflows** — Schedule reminder and follow-up emails relative to booking time, with template variables.
- **Public booking pages** — Visitors pick a date, see available slots in their timezone, and book with name + email.
- **Contacts & dashboard** — Track who's booked with you, export to CSV, view upcoming/recent bookings.
- **Rate limiting** — Rack::Attack throttles public booking endpoints out of the box.

## Requirements

- Ruby 3.4+
- SQLite3
- For production: a Linux server with Docker (Kamal handles the rest)

## Quick Start (Development)

```sh
git clone <your-fork-url>
cd uncal
bin/setup --skip-server
bin/rails setup:admin          # creates your first user (interactive prompts)
bin/dev                        # starts Rails + Tailwind CSS watcher
```

Open `http://localhost:3000` and sign in.

## Deploy to Production

Uncal uses [Kamal](https://kamal-deploy.org) for Docker-based deployment to any Linux server.

### 1. Prerequisites

- A server with Docker installed and SSH access
- A domain name pointed at your server
- SMTP credentials for sending email (any provider works)
- A Docker registry (Docker Hub, GitHub Container Registry, etc.)

### 2. Configure deployment

Edit `config/deploy.yml`:

```yaml
servers:
  web:
    - your.server.ip

proxy:
  ssl: true
  host: your-domain.com

registry:
  server: ghcr.io          # or hub.docker.com, etc.
  username: your-username
  password:
    - KAMAL_REGISTRY_PASSWORD
```

### 3. Set up credentials

Generate a master key and configure secrets:

```sh
bin/rails credentials:edit
```

Add your SMTP and Google Calendar credentials:

```yaml
smtp:
  user_name: your-smtp-username
  password: your-smtp-password

google:
  client_id: your-google-client-id
  client_secret: your-google-client-secret

active_record_encryption:
  primary_key: <run bin/rails db:encryption:init to generate>
  deterministic_key: <same>
  key_derivation_salt: <same>
```

Then uncomment the SMTP config in `config/environments/production.rb` and set your domain:

```ruby
config.action_mailer.default_url_options = { host: "your-domain.com" }

config.action_mailer.smtp_settings = {
  user_name: Rails.application.credentials.dig(:smtp, :user_name),
  password: Rails.application.credentials.dig(:smtp, :password),
  address: "smtp.your-provider.com",
  port: 587,
  authentication: :plain
}
```

Also uncomment `config.assume_ssl` and `config.force_ssl` if using SSL (you should).

### 4. Configure Kamal secrets

Edit `.kamal/secrets` to provide `RAILS_MASTER_KEY`. The default reads from `config/master.key`:

```sh
RAILS_MASTER_KEY=$(cat config/master.key)
```

For Docker registry auth, set `KAMAL_REGISTRY_PASSWORD` in your environment or `.kamal/secrets`.

### 5. Deploy

```sh
bin/kamal setup                # first deploy — provisions server, builds image, starts app
```

The container entrypoint automatically runs `db:prepare` on startup, so migrations are handled.

### 6. Create your admin user

```sh
bin/kamal console
# then in the Rails console, or:

bin/kamal app exec "bin/rails setup:admin NAME='Your Name' EMAIL='you@example.com' PASSWORD='secure-password'"
```

### 7. Subsequent deploys

```sh
bin/kamal deploy
```

### Google Calendar Setup

To enable Google Calendar integration:

1. Create a project in [Google Cloud Console](https://console.cloud.google.com)
2. Enable the Google Calendar API
3. Create OAuth 2.0 credentials (Web application type)
4. Set the authorized redirect URI to `https://your-domain.com/google_calendar/callback`
5. Add the client ID and secret to your Rails credentials (see step 3 above)

Users connect their calendars individually from the Settings page.

## Configuration

### Email

Email is required for invitations, booking confirmations, cancellations, and workflow automations. Configure SMTP in `config/environments/production.rb` as shown above.

In development, emails are captured by [letter_opener_web](https://github.com/fgrehm/letter_opener_web) at `/letter_opener`.

### Rate Limiting

Public booking endpoints are throttled by default:

- Booking page views: 30 requests/minute per IP
- Booking creation: 5 requests/minute per IP

Adjust in `config/initializers/rack_attack.rb`.

### Background Jobs

Solid Queue runs inside the Puma process by default (`SOLID_QUEUE_IN_PUMA=true`). This handles workflow email scheduling and booking cleanup. No separate worker process needed for small deployments.

Recurring jobs (configured in `config/recurring.yml`):
- Solid Queue cleanup — hourly
- Old booking pruning — daily at 3am

### Storage

All data lives in SQLite files under `/rails/storage` in the container (mapped to the `uncal_storage` Docker volume). **Back up this volume** — it contains your entire database.

## Usage

1. **Sign in** and visit Settings to set your timezone and connect Google Calendar
2. **Invite teammates** from the Invitations page — they'll get a 7-day link to join
3. **Create a schedule link** — set the meeting name, duration, location, and add team members
4. **Define availability** — set weekly windows (e.g., Mon-Fri 9am-5pm) on each link
5. **Share the booking URL** — visitors at `/book/your-slug` pick a time from the combined availability
6. **Set up workflows** (optional) — create email sequences triggered before/after bookings
7. **Manage bookings** from the dashboard — view upcoming meetings, cancel if needed, export contacts

## Staying Up to Date

To pull updates from the original repo into your fork:

```sh
# one-time setup
git remote add upstream https://github.com/ORIGINAL_OWNER/uncal.git

# pull updates
git fetch upstream
git merge upstream/main
```

After merging:

```sh
bin/rails db:migrate           # run any new migrations
bin/rails test                 # verify nothing broke
bin/kamal deploy               # ship it
```

Your configuration files (`config/deploy.yml`, `config/environments/production.rb`, credentials) won't conflict since they're either gitignored or unchanged upstream. View and stylesheet customizations may need manual merging.

## Running Tests

```sh
bin/rails test                 # unit + integration tests
bin/rails test:system          # browser tests (Capybara + Selenium)
bin/ci                         # full CI suite (tests + security scans + linting)
```

## License

[MIT](LICENSE)
