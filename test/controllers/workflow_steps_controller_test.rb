require "test_helper"

class WorkflowStepsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @workflow = workflows(:one)
  end

  test "create adds step to workflow" do
    assert_difference "WorkflowStep.count", 1 do
      post workflow_workflow_steps_path(@workflow), params: { workflow_step: {
        timing_direction: "after",
        timing_minutes: 120,
        email_subject: "Follow up",
        email_body: "Thanks for meeting!",
        recipient_type: "invitee"
      } }
    end

    assert_response :redirect
    step = WorkflowStep.last
    assert_equal @workflow, step.workflow
    assert_equal "after", step.timing_direction
    assert_equal 120, step.timing_minutes
  end

  test "create with turbo stream appends step" do
    assert_difference "WorkflowStep.count", 1 do
      post workflow_workflow_steps_path(@workflow), params: { workflow_step: {
        timing_direction: "before",
        timing_minutes: 30,
        email_subject: "Heads up",
        email_body: "Meeting soon",
        recipient_type: "host"
      } }, as: :turbo_stream
    end

    assert_response :success
  end

  test "create with invalid params returns error" do
    assert_no_difference "WorkflowStep.count" do
      post workflow_workflow_steps_path(@workflow), params: { workflow_step: {
        timing_direction: "",
        timing_minutes: 0,
        email_subject: "",
        email_body: "",
        recipient_type: "invitee"
      } }
    end
  end

  test "destroy removes step" do
    step = workflow_steps(:reminder_before)

    assert_difference "WorkflowStep.count", -1 do
      delete workflow_workflow_step_path(@workflow, step)
    end

    assert_response :redirect
  end

  test "destroy with turbo stream removes step" do
    step = workflow_steps(:followup_after)

    assert_difference "WorkflowStep.count", -1 do
      delete workflow_workflow_step_path(@workflow, step), as: :turbo_stream
    end

    assert_response :success
  end

  test "cannot manage steps on another users workflow" do
    other_workflow = users(:two).workflows.create!(name: "Other")

    post workflow_workflow_steps_path(other_workflow), params: { workflow_step: {
      timing_direction: "after",
      timing_minutes: 60,
      email_subject: "Test",
      email_body: "Body",
      recipient_type: "invitee"
    } }
    assert_response :not_found
  end

  test "auto-increments position" do
    max_pos = @workflow.workflow_steps.maximum(:position)

    post workflow_workflow_steps_path(@workflow), params: { workflow_step: {
      timing_direction: "after",
      timing_minutes: 60,
      email_subject: "Test",
      email_body: "Body",
      recipient_type: "invitee"
    } }

    assert_equal max_pos + 1, WorkflowStep.last.position
  end
end
