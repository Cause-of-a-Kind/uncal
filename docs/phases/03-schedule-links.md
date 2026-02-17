# Phase 3 — Schedule Links (Core)

## Goal

Users create schedule links with all configuration options. Links are shareable via a unique auto-generated slug.

## Tasks

- [ ] Create `ScheduleLink` model with migration (all fields from data model)
- [ ] Auto-generate slug: `SecureRandom.alphanumeric(8).downcase` with uniqueness validation
- [ ] Validations: presence of required fields, `meeting_duration_minutes > 0`, `max_future_days > 0`, `buffer_minutes >= 0`, `max_bookings_per_day > 0` (when present)
- [ ] Create `ScheduleLinkMember` join model with migration
- [ ] Relationships: `ScheduleLink has_many :members through :schedule_link_members`
- [ ] `ScheduleLinksController` (authenticated): index, new, create, edit, update, destroy
- [ ] Index: show links user is a member of or created
- [ ] Creation form Section 1 — Meeting Details: name, duration (select: 15/30/45/60/90/120 or custom), location type (radio: Video/Link or Physical Address), location value (conditional text field)
- [ ] Creation form Section 2 — Scheduling Rules: timezone (select, default to creator's), buffer (select: 0/15/30/45/60/90/120 min), max bookings/day (optional number), max future window (number, stored as days)
- [ ] Creation form Section 3 — Team Members: search/select users, creator always a member, list with remove buttons
- [ ] Show page: all config, public URL (`/book/{slug}`), copy-to-clipboard button, upcoming bookings list
- [ ] Status field: `active` (default) or `inactive`

## TDD Cycles

### Cycle 1: ScheduleLink Model
- [ ] Test: `ScheduleLink` validates presence of `name`, `meeting_name`, `meeting_duration_minutes`, `meeting_location_type`, `timezone`
- [ ] Test: `meeting_duration_minutes` must be greater than 0
- [ ] Test: `max_future_days` must be greater than 0
- [ ] Test: `buffer_minutes` must be >= 0
- [ ] Test: `max_bookings_per_day` must be > 0 when present (allow nil)
- [ ] Test: `meeting_location_type` must be "link" or "physical"
- [ ] Test: `status` defaults to "active"
- [ ] Test: slug auto-generated on create (8-char lowercase alphanumeric)
- [ ] Test: slug is unique (duplicate rejected)
- [ ] Test: `ScheduleLink belongs_to :created_by` (User)
- [ ] Implement: migration, model, validations, slug callback

### Cycle 2: ScheduleLinkMember Join Table
- [ ] Test: `ScheduleLinkMember` requires `schedule_link_id` and `user_id`
- [ ] Test: `ScheduleLink has_many :members through :schedule_link_members`
- [ ] Test: `User has_many :schedule_links through :schedule_link_members`
- [ ] Test: uniqueness of `(schedule_link_id, user_id)` pair
- [ ] Implement: migration, model, associations

### Cycle 3: ScheduleLinksController (CRUD)
- [ ] Test: index shows links where user is member or creator
- [ ] Test: index requires authentication
- [ ] Test: create with valid params creates link and adds creator as member
- [ ] Test: create with invalid params re-renders form with errors
- [ ] Test: edit/update modifies link fields
- [ ] Test: only creator or members can edit
- [ ] Test: destroy sets status to "inactive" (or hard deletes)
- [ ] Implement: controller, routes, form views

### Cycle 4: Creation Form (3 Sections)
- [ ] Test: form renders duration select with options (15/30/45/60/90/120)
- [ ] Test: form renders location type radio (link/physical)
- [ ] Test: form renders timezone select defaulting to user's timezone
- [ ] Test: form renders buffer select (0/15/30/45/60/90/120)
- [ ] Test: creating with team members adds them as `ScheduleLinkMember` records
- [ ] Test: creator is always added as a member even if not explicitly selected
- [ ] Test: show page displays public URL with slug
- [ ] Implement: multi-section form, team member selection, show page

## Key Files

```
app/models/schedule_link.rb
app/models/schedule_link_member.rb
app/controllers/schedule_links_controller.rb
app/views/schedule_links/index.html.erb
app/views/schedule_links/new.html.erb
app/views/schedule_links/_form.html.erb
app/views/schedule_links/show.html.erb
app/views/schedule_links/edit.html.erb
db/migrate/*_create_schedule_links.rb
db/migrate/*_create_schedule_link_members.rb
config/routes.rb (updated)
test/models/schedule_link_test.rb
test/models/schedule_link_member_test.rb
test/controllers/schedule_links_controller_test.rb
```

## Acceptance Criteria

- [ ] User can create a schedule link with all configuration options
- [ ] Slug auto-generated and unique
- [ ] Can have one or many team members
- [ ] Creator automatically added as a member
- [ ] All config editable after creation
- [ ] Public URL displayed and copyable on show page
- [ ] Index shows all links the user is associated with
