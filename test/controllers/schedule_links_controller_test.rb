require "test_helper"

class ScheduleLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "index requires authentication" do
    sign_out
    get schedule_links_path
    assert_redirected_to new_session_path
  end

  test "index shows links where user is member or creator" do
    get schedule_links_path
    assert_response :success
    assert_select "a[href=?]", schedule_link_path(schedule_links(:one))
  end

  test "create with valid params creates link and adds creator as member" do
    assert_difference "ScheduleLink.count", 1 do
      post schedule_links_path, params: { schedule_link: {
        name: "New Link",
        meeting_name: "Intro Call",
        meeting_duration_minutes: 30,
        meeting_location_type: "link",
        meeting_location_value: "https://zoom.us/j/456",
        timezone: "America/New_York",
        buffer_minutes: 0,
        max_future_days: 30
      } }
    end

    link = ScheduleLink.last
    assert_redirected_to schedule_link_path(link)
    assert_equal users(:one), link.created_by
    assert_includes link.members, users(:one)
  end

  test "create with invalid params re-renders form with errors" do
    assert_no_difference "ScheduleLink.count" do
      post schedule_links_path, params: { schedule_link: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "edit and update modifies link fields" do
    link = schedule_links(:one)
    get edit_schedule_link_path(link)
    assert_response :success

    patch schedule_link_path(link), params: { schedule_link: { name: "Updated Name" } }
    assert_redirected_to schedule_link_path(link)
    assert_equal "Updated Name", link.reload.name
  end

  test "only creator or members can edit" do
    sign_out
    sign_in_as users(:two)

    link = schedule_links(:one)
    get edit_schedule_link_path(link)
    assert_redirected_to schedule_links_path
  end

  test "destroy sets status to inactive" do
    link = schedule_links(:one)
    delete schedule_link_path(link)
    assert_redirected_to schedule_links_path
    assert_equal "inactive", link.reload.status
  end
end
