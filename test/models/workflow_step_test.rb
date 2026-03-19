require "test_helper"

class WorkflowStepTest < ActiveSupport::TestCase
  test "valid workflow step" do
    step = workflow_steps(:reminder_before)
    assert step.valid?
  end

  test "belongs to workflow" do
    step = workflow_steps(:reminder_before)
    assert_equal workflows(:one), step.workflow
  end

  test "validates timing_direction inclusion" do
    step = workflow_steps(:reminder_before)
    step.timing_direction = "during"
    assert_not step.valid?
    assert_includes step.errors[:timing_direction], "is not included in the list"
  end

  test "validates timing_minutes greater than 0" do
    step = workflow_steps(:reminder_before)
    step.timing_minutes = 0
    assert_not step.valid?
    assert_includes step.errors[:timing_minutes], "must be greater than 0"
  end

  test "validates timing_minutes presence" do
    step = workflow_steps(:reminder_before)
    step.timing_minutes = nil
    assert_not step.valid?
    assert_includes step.errors[:timing_minutes], "can't be blank"
  end

  test "validates email_subject presence" do
    step = workflow_steps(:reminder_before)
    step.email_subject = nil
    assert_not step.valid?
    assert_includes step.errors[:email_subject], "can't be blank"
  end

  test "validates email_body presence" do
    step = workflow_steps(:reminder_before)
    step.email_body = nil
    assert_not step.valid?
    assert_includes step.errors[:email_body], "can't be blank"
  end

  test "validates recipient_type inclusion" do
    step = workflow_steps(:reminder_before)
    step.recipient_type = "nobody"
    assert_not step.valid?
    assert_includes step.errors[:recipient_type], "is not included in the list"
  end

  test "recipient_type defaults to invitee" do
    step = WorkflowStep.new(
      workflow: workflows(:one),
      timing_direction: "after",
      timing_minutes: 30,
      email_subject: "Test",
      email_body: "Test body"
    )
    assert_equal "invitee", step.recipient_type
  end

  test "allows before and after timing directions" do
    step = workflow_steps(:reminder_before)

    step.timing_direction = "before"
    assert step.valid?

    step.timing_direction = "after"
    assert step.valid?
  end

  test "allows invitee, host, and all recipient types" do
    step = workflow_steps(:reminder_before)

    %w[invitee host all].each do |type|
      step.recipient_type = type
      assert step.valid?, "Expected #{type} to be valid"
    end
  end

  test "step with valid template variables passes validation" do
    step = workflow_steps(:reminder_before)
    step.email_subject = "Reminder for {{meeting_name}}"
    step.email_body = "Hi {{invitee_name}}, your meeting is on {{meeting_date}} at {{meeting_time}}."
    assert step.valid?
  end

  test "step with no template variables passes validation" do
    step = workflow_steps(:reminder_before)
    step.email_subject = "Plain subject"
    step.email_body = "Plain body with no variables"
    assert step.valid?
  end

  test "step with unknown variable in subject is invalid" do
    step = workflow_steps(:reminder_before)
    step.email_subject = "Reminder for {{event_name}}"
    assert_not step.valid?
    assert_includes step.errors[:email_subject].join, "event_name"
  end

  test "step with unknown variable in body is invalid" do
    step = workflow_steps(:reminder_before)
    step.email_body = "See you at {{event_location}}"
    assert_not step.valid?
    assert_includes step.errors[:email_body].join, "event_location"
  end

  test "error message lists specific unknown variable names" do
    step = workflow_steps(:reminder_before)
    step.email_body = "{{foo}} and {{bar}}"
    assert_not step.valid?
    error = step.errors[:email_body].join
    assert_includes error, "foo"
    assert_includes error, "bar"
  end

  test "error message includes allowed variable names" do
    step = workflow_steps(:reminder_before)
    step.email_body = "{{typo_name}}"
    assert_not step.valid?
    error = step.errors[:email_body].join
    assert_includes error, "typo_name"
    assert_includes error, "Allowed:"
    assert_includes error, "{{invitee_name}}"
    assert_includes error, "{{meeting_name}}"
  end

  test "step with mix of valid and unknown variables is invalid" do
    step = workflow_steps(:reminder_before)
    step.email_body = "Hi {{invitee_name}}, your {{event_name}} is soon"
    assert_not step.valid?
    assert_includes step.errors[:email_body].join, "event_name"
  end
end
