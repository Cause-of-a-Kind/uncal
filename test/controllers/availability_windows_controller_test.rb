require "test_helper"

class AvailabilityWindowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @link = schedule_links(:one)
    sign_in_as @user
  end

  # --- Index ---

  test "index requires authentication" do
    sign_out
    get schedule_link_availability_windows_path(@link)
    assert_redirected_to new_session_path
  end

  test "index shows availability windows for the link" do
    get schedule_link_availability_windows_path(@link)
    assert_response :success
    assert_match "9:00 AM", response.body
  end

  test "non-creator cannot access availability windows" do
    @link.members << users(:two)
    sign_out
    sign_in_as users(:two)

    get schedule_link_availability_windows_path(@link)
    assert_redirected_to schedule_links_path
  end

  # --- Create ---

  test "create adds a window and responds with turbo_stream" do
    assert_difference "AvailabilityWindow.count", 1 do
      post schedule_link_availability_windows_path(@link), params: {
        availability_window: {
          day_of_week: 4,
          start_time: "10:00",
          end_time: "11:00"
        }
      }, as: :turbo_stream
    end
    assert_response :success
  end

  test "create with invalid params returns error" do
    # Overlaps with fixture one_monday_morning (14:00-17:00 UTC)
    assert_no_difference "AvailabilityWindow.count" do
      post schedule_link_availability_windows_path(@link), params: {
        availability_window: {
          day_of_week: 0,
          start_time: "15:00",
          end_time: "19:00"
        }
      }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "non-creator member cannot create windows" do
    @link.members << users(:two)
    sign_out
    sign_in_as users(:two)

    assert_no_difference "AvailabilityWindow.count" do
      post schedule_link_availability_windows_path(@link), params: {
        availability_window: {
          day_of_week: 3,
          start_time: "09:00",
          end_time: "10:00"
        }
      }, as: :turbo_stream
    end
    assert_redirected_to schedule_links_path
  end

  # --- Destroy ---

  test "destroy removes window" do
    window = availability_windows(:one_monday_morning)
    assert_difference "AvailabilityWindow.count", -1 do
      delete schedule_link_availability_window_path(@link, window), as: :turbo_stream
    end
    assert_response :success
  end

  # --- Copy ---

  test "copy replace mode deletes existing windows then copies" do
    link_two = schedule_links(:two)
    # Transfer ownership of link_two to user one so they can copy from it
    link_two.update!(created_by: @user)

    existing_count = @link.availability_windows.count
    assert_equal 3, existing_count

    post copy_schedule_link_availability_windows_path(@link), params: {
      source_link_id: link_two.id,
      mode: "replace"
    }

    assert_redirected_to schedule_link_availability_windows_path(@link)

    # Should now have 2 windows (copied from link two), not 3 + 2
    assert_equal 2, @link.availability_windows.count
  end

  test "copy merge mode adds windows without duplicating overlapping" do
    link_two = schedule_links(:two)
    link_two.update!(created_by: @user)

    # Link one has windows on day 0 (14:00-17:00, 18:00-22:00 UTC) and day 2 (14:00-22:00 UTC)
    # Link two has windows on day 0 (08:00-11:00 UTC) and day 1 (10:00-16:00 UTC)
    initial_count = @link.availability_windows.count
    assert_equal 3, initial_count

    post copy_schedule_link_availability_windows_path(@link), params: {
      source_link_id: link_two.id,
      mode: "merge"
    }

    assert_redirected_to schedule_link_availability_windows_path(@link)

    # Should have 3 original + 2 new (both day 0 and day 1 from link two don't overlap)
    assert_equal 5, @link.availability_windows.count
  end

  test "cannot copy from a link user did not create" do
    # Link two is created by user two, so user one can't use it as source
    post copy_schedule_link_availability_windows_path(@link), params: {
      source_link_id: schedule_links(:two).id,
      mode: "replace"
    }

    assert_response :not_found
  end
end
