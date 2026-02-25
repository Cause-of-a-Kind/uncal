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
end
