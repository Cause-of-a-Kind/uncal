# Phase 7 — Email Workflows

## Goal

Schedule link owners define automated email sequences triggered relative to meeting times. Emails are scheduled via Solid Queue and cancelled if the booking is cancelled.

## Tasks

- [ ] Create `Workflow` model with migration
- [ ] Create `WorkflowStep` model with migration
- [ ] Validations: `timing_minutes > 0`, `timing_direction` in `["before", "after"]`, `recipient_type` in `["invitee", "host", "all"]`
- [ ] Steps ordered by `position`
- [ ] Build workflow management UI (accessible from ScheduleLink edit/show)
- [ ] One workflow per link with multiple steps
- [ ] Each step form row: timing (number + minutes/hours/days select + before/after), email subject, email body (textarea with variable hints), recipient radio
- [ ] Add/remove steps with Turbo Frames (no page reload)
- [ ] Optional drag-to-reorder for step position
- [ ] Schedule workflow emails on booking creation:
  - `before`: send at `booking.start_time - timing_minutes`
  - `after`: send at `booking.end_time + timing_minutes`
  - Skip if calculated send time is in the past
  - Enqueue `WorkflowEmailJob` with `set(wait_until: send_time)`
- [ ] `WorkflowEmailJob`: receives `workflow_step_id` and `booking_id`, checks booking still confirmed and workflow still active, interpolates variables, sends via Action Mailer
- [ ] Cancel scheduled emails on booking cancellation (delete/discard pending Solid Queue jobs)
- [ ] Belt-and-suspenders: job checks booking status before sending
- [ ] Workflow state toggleable: `active` / `inactive`

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
- [ ] Test: `Workflow` validates presence of `name`, `schedule_link`
- [ ] Test: `Workflow` state defaults to "active"
- [ ] Test: `Workflow belongs_to :schedule_link`
- [ ] Test: `ScheduleLink has_one :workflow`
- [ ] Test: `WorkflowStep` validates presence of `timing_direction`, `timing_minutes`, `email_subject`, `email_body`
- [ ] Test: `timing_direction` must be "before" or "after"
- [ ] Test: `timing_minutes` must be > 0
- [ ] Test: `recipient_type` must be "invitee", "host", or "all"
- [ ] Test: `recipient_type` defaults to "invitee"
- [ ] Test: steps ordered by `position`
- [ ] Test: `Workflow has_many :workflow_steps, dependent: :destroy`
- [ ] Implement: migrations, models, validations

### Cycle 2: Workflow Management UI
- [ ] Test: workflow UI accessible from schedule link page
- [ ] Test: can add a workflow step with all fields
- [ ] Test: can remove a workflow step
- [ ] Test: adding step uses Turbo Frame (no full reload)
- [ ] Test: can toggle workflow between active and inactive
- [ ] Test: step form shows timing fields, subject, body, recipient selector
- [ ] Implement: `WorkflowsController`, `WorkflowStepsController`, views

### Cycle 3: WorkflowEmailJob Scheduling
- [ ] Test: creating a booking enqueues `WorkflowEmailJob` for each active step
- [ ] Test: "before" step: job scheduled at `start_time - timing_minutes`
- [ ] Test: "after" step: job scheduled at `end_time + timing_minutes`
- [ ] Test: past send times are skipped (not enqueued)
- [ ] Test: inactive workflow steps not scheduled
- [ ] Implement: scheduling logic in booking creation flow

### Cycle 4: Cancellation of Scheduled Jobs
- [ ] Test: cancelling a booking discards all pending workflow jobs for that booking
- [ ] Test: already-sent jobs unaffected by cancellation
- [ ] Test: job checks booking status is "confirmed" before sending
- [ ] Test: job checks workflow is "active" before sending
- [ ] Test: job does nothing if booking cancelled (belt-and-suspenders)
- [ ] Implement: cancellation logic, status checks in job

### Cycle 5: Variable Interpolation
- [ ] Test: `{{invitee_name}}` replaced with booking's invitee name
- [ ] Test: `{{invitee_email}}` replaced with booking's invitee email
- [ ] Test: `{{meeting_name}}` replaced with schedule link's meeting name
- [ ] Test: `{{meeting_date}}` replaced with formatted date in link's timezone
- [ ] Test: `{{meeting_time}}` replaced with formatted time in link's timezone
- [ ] Test: `{{meeting_duration}}` replaced with human-readable duration
- [ ] Test: `{{meeting_location}}` replaced with location value
- [ ] Test: `{{host_names}}` replaced with comma-separated member names
- [ ] Test: unknown variables left as-is (not stripped)
- [ ] Implement: interpolation method in `WorkflowEmailJob` or helper

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

- [ ] User can add a workflow with multiple steps to a schedule link
- [ ] Each step specifies timing (minutes before/after), email content, and recipients
- [ ] Emails scheduled correctly on booking creation
- [ ] Scheduled emails cancelled on booking cancellation
- [ ] Template variables interpolated correctly in subject and body
- [ ] Past-time emails skipped (not sent immediately)
- [ ] Workflow state toggleable between active and inactive
- [ ] Job double-checks booking and workflow status before sending
