require "test_helper"

class WorkflowTest < ActiveSupport::TestCase
  test "valid workflow" do
    workflow = workflows(:one)
    assert workflow.valid?
  end

  test "validates presence of name" do
    workflow = workflows(:one)
    workflow.name = nil
    assert_not workflow.valid?
    assert_includes workflow.errors[:name], "can't be blank"
  end

  test "validates state inclusion" do
    workflow = workflows(:one)
    workflow.state = "unknown"
    assert_not workflow.valid?
    assert_includes workflow.errors[:state], "is not included in the list"
  end

  test "state defaults to active" do
    workflow = Workflow.new(name: "Test", user: users(:one))
    assert_equal "active", workflow.state
  end

  test "belongs to user" do
    workflow = workflows(:one)
    assert_equal users(:one), workflow.user
  end

  test "has many workflow_steps ordered by position" do
    workflow = workflows(:one)
    assert_equal 3, workflow.workflow_steps.count
    positions = workflow.workflow_steps.pluck(:position)
    assert_equal positions.sort, positions
  end

  test "dependent destroy removes steps" do
    workflow = Workflow.create!(name: "Temp", user: users(:one))
    workflow.workflow_steps.create!(
      timing_direction: "after", timing_minutes: 30,
      email_subject: "Test", email_body: "Body", position: 0
    )

    assert_difference "WorkflowStep.count", -1 do
      workflow.destroy!
    end
  end

  test "has many schedule_links" do
    workflow = workflows(:one)
    assert_includes workflow.schedule_links, schedule_links(:one)
  end

  test "active scope returns only active workflows" do
    active = Workflow.active
    assert_includes active, workflows(:one)
    assert_not_includes active, workflows(:inactive_one)
  end

  test "user has many workflows" do
    user = users(:one)
    assert_includes user.workflows, workflows(:one)
    assert_includes user.workflows, workflows(:inactive_one)
  end

  test "destroying user destroys workflows" do
    user = users(:two)
    user.workflows.create!(name: "Temp")

    assert_difference "Workflow.count", -1 do
      user.destroy!
    end
  end
end
