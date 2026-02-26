# Phase 7 — Email Workflows

## Status: COMPLETE

## Goal

Schedule link owners define automated email sequences triggered relative to meeting times. Emails are scheduled via Solid Queue and cancelled if the booking is cancelled.

## Tasks

- [x] Create `Workflow` model with migration
- [x] Create `WorkflowStep` model with migration
- [x] Validations: `timing_minutes > 0`, `timing_direction` in `["before", "after"]`, `recipient_type` in `["invitee", "host", "all"]`
- [x] Steps ordered by `position`
- [x] Build workflow management UI (accessible from ScheduleLink edit/show)
- [x] One workflow per link with multiple steps
- [x] Each step form row: timing (number + minutes/hours/days select + before/after), email subject, email body (textarea with variable hints), recipient radio
- [x] Add/remove steps with Turbo Frames (no page reload)
- [x] Optional drag-to-reorder for step position
- [x] Schedule workflow emails on booking creation:
  - `before`: send at `booking.start_time - timing_minutes`
  - `after`: send at `booking.end_time + timing_minutes`
  - Skip if calculated send time is in the past
  - Enqueue `WorkflowEmailJob` with `set(wait_until: send_time)`
- [x] `WorkflowEmailJob`: receives `workflow_step_id` and `booking_id`, checks booking still confirmed and workflow still active, interpolates variables, sends via Action Mailer
- [x] Cancel scheduled emails on booking cancellation (delete/discard pending Solid Queue jobs)
- [x] Belt-and-suspenders: job checks booking status before sending
- [x] Workflow state toggleable: `active` / `inactive`

## Template Variables

| Variable | Value |
|----------|-------|
| `{{invitee_name}}` | Booker's name |
| `{{invitee_email}}` | Booker's email |
| `{{meeting_name}}` | Meeting name from schedule link |
| `{{meeting_date}}` | Formatted date in schedule link's timezone |
| `{{meeting_time}}` | Formatted start time in schedule link's timezone |
| `{{meeting_duration}}` | e.g., "30 minutes" |
| `{{meeting_location}}` | Location value |
| `{{host_names}}` | Comma-separated member names |

Implementation: simple string replacement (`gsub`), no template engine.

## TDD Cycles

### Cycle 1: Workflow & WorkflowStep Models
- [x] Test: `Workflow` validates presence of `name`, `schedule_link`
- [x] Test: `Workflow` state defaults to "active"
- [x] Test: `Workflow belongs_to :schedule_link`
- [x] Test: `ScheduleLink has_one :workflow`
- [x] Test: `WorkflowStep` validates presence of `timing_direction`, `timing_minutes`, `email_subject`, `email_body`
- [x] Test: `timing_direction` must be "before" or "after"
- [x] Test: `timing_minutes` must be > 0
- [x] Test: `recipient_type` must be "invitee", "host", or "all"
- [x] Test: `recipient_type` defaults to "invitee"
- [x] Test: steps ordered by `position`
- [x] Test: `Workflow has_many :workflow_steps, dependent: :destroy`
- [x] Implement: migrations, models, validations

### Cycle 2: Workflow Management UI
- [x] Test: workflow UI accessible from schedule link page
- [x] Test: can add a workflow step with all fields
- [x] Test: can remove a workflow step
- [x] Test: adding step uses Turbo Frame (no full reload)
- [x] Test: can toggle workflow between active and inactive
- [x] Test: step form shows timing fields, subject, body, recipient selector
- [x] Implement: `WorkflowsController`, `WorkflowStepsController`, views

### Cycle 3: WorkflowEmailJob Scheduling
- [x] Test: creating a booking enqueues `WorkflowEmailJob` for each active step
- [x] Test: "before" step: job scheduled at `start_time - timing_minutes`
- [x] Test: "after" step: job scheduled at `end_time + timing_minutes`
- [x] Test: past send times are skipped (not enqueued)
- [x] Test: inactive workflow steps not scheduled
- [x] Implement: scheduling logic in booking creation flow

### Cycle 4: Cancellation of Scheduled Jobs
- [x] Test: cancelling a booking discards all pending workflow jobs for that booking
- [x] Test: already-sent jobs unaffected by cancellation
- [x] Test: job checks booking status is "confirmed" before sending
- [x] Test: job checks workflow is "active" before sending
- [x] Test: job does nothing if booking cancelled (belt-and-suspenders)
- [x] Implement: cancellation logic, status checks in job

### Cycle 5: Variable Interpolation
- [x] Test: `{{invitee_name}}` replaced with booking's invitee name
- [x] Test: `{{invitee_email}}` replaced with booking's invitee email
- [x] Test: `{{meeting_name}}` replaced with schedule link's meeting name
- [x] Test: `{{meeting_date}}` replaced with formatted date in link's timezone
- [x] Test: `{{meeting_time}}` replaced with formatted time in link's timezone
- [x] Test: `{{meeting_duration}}` replaced with human-readable duration
- [x] Test: `{{meeting_location}}` replaced with location value
- [x] Test: `{{host_names}}` replaced with comma-separated member names
- [x] Test: unknown variables left as-is (not stripped)
- [x] Implement: interpolation method in `WorkflowEmailJob` or helper

## Key Files

```
app/models/workflow.rb
app/models/workflow_step.rb
app/controllers/workflows_controller.rb
app/controllers/workflow_steps_controller.rb
app/jobs/workflow_email_job.rb
app/mailers/workflow_mailer.rb
app/views/workflows/_form.html.erb
app/views/workflow_steps/_step.html.erb
app/views/workflow_steps/_form.html.erb
db/migrate/*_create_workflows.rb
db/migrate/*_create_workflow_steps.rb
config/routes.rb (updated — nested resources)
test/models/workflow_test.rb
test/models/workflow_step_test.rb
test/jobs/workflow_email_job_test.rb
test/controllers/workflows_controller_test.rb
```

## Acceptance Criteria

- [x] User can add a workflow with multiple steps to a schedule link
- [x] Each step specifies timing (minutes before/after), email content, and recipients
- [x] Emails scheduled correctly on booking creation
- [x] Scheduled emails cancelled on booking cancellation
- [x] Template variables interpolated correctly in subject and body
- [x] Past-time emails skipped (not sent immediately)
- [x] Workflow state toggleable between active and inactive
- [x] Job double-checks booking and workflow status before sending
