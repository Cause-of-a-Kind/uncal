require "test_helper"

class WorkflowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "index requires authentication" do
    sign_out
    get workflows_path
    assert_redirected_to new_session_path
  end

  test "index lists current user workflows" do
    get workflows_path
    assert_response :success
    assert_match "Booking Reminders", response.body
  end

  test "new renders form" do
    get new_workflow_path
    assert_response :success
    assert_match "New Workflow", response.body
  end

  test "create with valid params creates workflow" do
    assert_difference "Workflow.count", 1 do
      post workflows_path, params: { workflow: { name: "New Flow" } }
    end

    workflow = Workflow.last
    assert_redirected_to workflow_path(workflow)
    assert_equal "New Flow", workflow.name
    assert_equal users(:one), workflow.user
    assert_equal "active", workflow.state
  end

  test "create with invalid params re-renders form" do
    assert_no_difference "Workflow.count" do
      post workflows_path, params: { workflow: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "show displays workflow and steps" do
    get workflow_path(workflows(:one))
    assert_response :success
    assert_match "Booking Reminders", response.body
    assert_match "60 min before", response.body
  end

  test "edit renders form" do
    get edit_workflow_path(workflows(:one))
    assert_response :success
  end

  test "update with valid params updates workflow" do
    patch workflow_path(workflows(:one)), params: { workflow: { name: "Updated" } }
    assert_redirected_to workflow_path(workflows(:one))
    assert_equal "Updated", workflows(:one).reload.name
  end

  test "update with invalid params re-renders form" do
    patch workflow_path(workflows(:one)), params: { workflow: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "destroy deletes workflow" do
    workflow = Current.user.workflows.create!(name: "Temp")

    assert_difference "Workflow.count", -1 do
      delete workflow_path(workflow)
    end
    assert_redirected_to workflows_path
  end

  test "toggle switches active to inactive" do
    workflow = workflows(:one)
    assert_equal "active", workflow.state

    patch toggle_workflow_path(workflow)
    assert_redirected_to workflow_path(workflow)
    assert_equal "inactive", workflow.reload.state
  end

  test "toggle switches inactive to active" do
    workflow = workflows(:inactive_one)
    assert_equal "inactive", workflow.state

    patch toggle_workflow_path(workflow)
    assert_redirected_to workflow_path(workflow)
    assert_equal "active", workflow.reload.state
  end

  test "cannot access another user workflows" do
    other_workflow = users(:two).workflows.create!(name: "Other")

    get workflow_path(other_workflow)
    assert_response :not_found
  end
end
