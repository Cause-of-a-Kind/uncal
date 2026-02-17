# Phase 4 — Availability Windows

## Goal

Each member of a schedule link defines their weekly availability specific to that link. Windows can be copied between links for convenience.

## Tasks

- [ ] Create `AvailabilityWindow` model with migration
- [ ] Validations: `start_time < end_time`, `day_of_week` in 0..6
- [ ] Uniqueness scoped to prevent exact duplicates
- [ ] Custom validation to prevent overlapping windows for same user/day/schedule_link
- [ ] Composite index on `(schedule_link_id, user_id, day_of_week)`
- [ ] Build availability management UI nested under schedule links
- [ ] Route: `GET /schedule_links/:schedule_link_id/availability`
- [ ] Multi-member view: tab/dropdown to switch between members
- [ ] Creators can edit all members' windows; members edit only their own
- [ ] Weekly grid display (Mon-Sun) showing windows per day with delete buttons
- [ ] "Add Window" per day: inline Turbo Frame form
- [ ] Time selects: 15-minute increments from 00:00 to 23:45
- [ ] Turbo Stream responses for add/remove (no full page reload)
- [ ] "Copy from another schedule link" action
- [ ] Copy options: "Replace existing" or "Merge"
- [ ] `AvailabilityWindowsController` nested under schedule_links
- [ ] Scoped to schedule link and current user (or any member if creator)
- [ ] `copy` action for bulk-copying windows between links

## TDD Cycles

### Cycle 1: AvailabilityWindow Model
- [ ] Test: requires `schedule_link`, `user`, `day_of_week`, `start_time`, `end_time`
- [ ] Test: `day_of_week` must be 0..6
- [ ] Test: `start_time` must be before `end_time`
- [ ] Test: rejects overlapping windows for same user/day/schedule_link
- [ ] Test: allows same times on different days for same user/link
- [ ] Test: allows same times on same day for different links
- [ ] Test: allows same times on same day for different users on same link
- [ ] Test: `belongs_to :schedule_link` and `belongs_to :user`
- [ ] Implement: migration, model, validations

### Cycle 2: AvailabilityWindowsController
- [ ] Test: requires authentication
- [ ] Test: scoped to schedule link — can't access windows from other links
- [ ] Test: creator can view/edit all members' windows
- [ ] Test: member can only edit their own windows
- [ ] Test: create adds window and returns Turbo Stream
- [ ] Test: destroy removes window and returns Turbo Stream
- [ ] Test: rejects overlapping window with validation error
- [ ] Implement: nested controller, routes

### Cycle 3: Weekly Grid UI
- [ ] Test: availability page shows 7-day grid (Mon-Sun)
- [ ] Test: existing windows displayed in correct day columns
- [ ] Test: "Add Window" form appears inline via Turbo Frame
- [ ] Test: time selects show 15-minute increments (00:00 to 23:45)
- [ ] Test: adding a window updates grid without full page reload
- [ ] Test: removing a window updates grid without full page reload
- [ ] Test: times displayed in schedule link's timezone
- [ ] Implement: grid view, Turbo Frame forms, Stimulus controller (if needed)

### Cycle 4: Copy Between Links
- [ ] Test: copy action shows dropdown of user's other links that have windows
- [ ] Test: "Replace existing" mode deletes current windows before copying
- [ ] Test: "Merge" mode adds copied windows alongside existing ones
- [ ] Test: merge mode skips windows that would overlap with existing
- [ ] Test: copy creates new `AvailabilityWindow` records (not references)
- [ ] Implement: copy action, copy UI

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

- [ ] Each member has their own availability windows per schedule link
- [ ] User can have different availability on different links
- [ ] Can add one or many windows per day per link
- [ ] Can delete individual windows
- [ ] Overlapping windows rejected with validation error
- [ ] Can copy availability between links (replace or merge)
- [ ] UI updates inline via Turbo (no full page reload)
- [ ] Times displayed in schedule link's timezone
