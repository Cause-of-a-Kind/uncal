# Phase 4 — Availability Windows

## Goal

Each member of a schedule link defines their weekly availability specific to that link. Windows can be copied between links for convenience.

## Tasks

- [x] Create `AvailabilityWindow` model with migration
- [x] Validations: `start_time < end_time`, `day_of_week` in 0..6
- [x] Uniqueness scoped to prevent exact duplicates
- [x] Custom validation to prevent overlapping windows for same user/day/schedule_link
- [x] Composite index on `(schedule_link_id, user_id, day_of_week)`
- [x] Build availability management UI nested under schedule links
- [x] Route: `GET /schedule_links/:schedule_link_id/availability`
- [x] Multi-member view: tab/dropdown to switch between members
- [x] Creators can edit all members' windows; members edit only their own
- [x] Weekly grid display (Mon-Sun) showing windows per day with delete buttons
- [x] "Add Window" per day: inline Turbo Frame form
- [x] Time selects: 15-minute increments from 00:00 to 23:45
- [x] Turbo Stream responses for add/remove (no full page reload)
- [x] "Copy from another schedule link" action
- [x] Copy options: "Replace existing" or "Merge"
- [x] `AvailabilityWindowsController` nested under schedule_links
- [x] Scoped to schedule link and current user (or any member if creator)
- [x] `copy` action for bulk-copying windows between links

## TDD Cycles

### Cycle 1: AvailabilityWindow Model
- [x] Test: requires `schedule_link`, `user`, `day_of_week`, `start_time`, `end_time`
- [x] Test: `day_of_week` must be 0..6
- [x] Test: `start_time` must be before `end_time`
- [x] Test: rejects overlapping windows for same user/day/schedule_link
- [x] Test: allows same times on different days for same user/link
- [x] Test: allows same times on same day for different links
- [x] Test: allows same times on same day for different users on same link
- [x] Test: `belongs_to :schedule_link` and `belongs_to :user`
- [x] Implement: migration, model, validations

### Cycle 2: AvailabilityWindowsController
- [x] Test: requires authentication
- [x] Test: scoped to schedule link — can't access windows from other links
- [x] Test: creator can view/edit all members' windows
- [x] Test: member can only edit their own windows
- [x] Test: create adds window and returns Turbo Stream
- [x] Test: destroy removes window and returns Turbo Stream
- [x] Test: rejects overlapping window with validation error
- [x] Implement: nested controller, routes

### Cycle 3: Weekly Grid UI
- [x] Test: availability page shows 7-day grid (Mon-Sun)
- [x] Test: existing windows displayed in correct day columns
- [x] Test: "Add Window" form appears inline via Turbo Frame
- [x] Test: time selects show 15-minute increments (00:00 to 23:45)
- [x] Test: adding a window updates grid without full page reload
- [x] Test: removing a window updates grid without full page reload
- [x] Test: times displayed in schedule link's timezone
- [x] Implement: grid view, Turbo Frame forms, Stimulus controller (if needed)

### Cycle 4: Copy Between Links
- [x] Test: copy action shows dropdown of user's other links that have windows
- [x] Test: "Replace existing" mode deletes current windows before copying
- [x] Test: "Merge" mode adds copied windows alongside existing ones
- [x] Test: merge mode skips windows that would overlap with existing
- [x] Test: copy creates new `AvailabilityWindow` records (not references)
- [x] Implement: copy action, copy UI

## Key Files

```
app/models/availability_window.rb
app/controllers/availability_windows_controller.rb
app/views/availability_windows/index.html.erb
app/views/availability_windows/_window.html.erb
app/views/availability_windows/_form.html.erb
app/views/availability_windows/_day_column.html.erb
app/views/availability_windows/copy.html.erb
db/migrate/*_create_availability_windows.rb
config/routes.rb (updated — nested resource)
test/models/availability_window_test.rb
test/controllers/availability_windows_controller_test.rb
```

## Acceptance Criteria

- [x] Each member has their own availability windows per schedule link
- [x] User can have different availability on different links
- [x] Can add one or many windows per day per link
- [x] Can delete individual windows
- [x] Overlapping windows rejected with validation error
- [x] Can copy availability between links (replace or merge)
- [x] UI updates inline via Turbo (no full page reload)
- [x] Times displayed in schedule link's timezone
