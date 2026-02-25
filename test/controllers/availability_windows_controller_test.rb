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

  test "index shows availability for current user" do
    get schedule_link_availability_windows_path(@link)
    assert_response :success
    assert_match "9:00 AM", response.body
  end

  test "creator can view other member's windows via user_id param" do
    # Add user two as member
    @link.members << users(:two)
    # Create a window for user two
    AvailabilityWindow.create!(
      schedule_link: @link, user: users(:two),
      day_of_week: 1, start_time: "10:00", end_time: "11:00"
    )

    get schedule_link_availability_windows_path(@link, user_id: users(:two).id)
    assert_response :success
  end

  test "non-member cannot access" do
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
    # Overlaps with fixture one_monday_morning (09:00-12:00)
    assert_no_difference "AvailabilityWindow.count" do
      post schedule_link_availability_windows_path(@link), params: {
        availability_window: {
          day_of_week: 0,
          start_time: "10:00",
          end_time: "14:00"
        }
      }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "creator can create window for another member" do
    @link.members << users(:two)

    assert_difference "AvailabilityWindow.count", 1 do
      post schedule_link_availability_windows_path(@link), params: {
        availability_window: {
          user_id: users(:two).id,
          day_of_week: 3,
          start_time: "09:00",
          end_time: "10:00"
        }
      }, as: :turbo_stream
    end
    assert_equal users(:two), AvailabilityWindow.last.user
  end

  test "member cannot create window for another user" do
    @link.members << users(:two)
    sign_out
    sign_in_as users(:two)

    post schedule_link_availability_windows_path(@link), params: {
      availability_window: {
        user_id: @user.id,
        day_of_week: 3,
        start_time: "09:00",
        end_time: "10:00"
      }
    }, as: :turbo_stream

    # Should create for current user (two), not the requested user
    assert_equal users(:two), AvailabilityWindow.last.user
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

    # User one has 3 windows on link one, 2 on link two (fixtures)
    existing_count = @link.availability_windows.where(user: @user).count
    assert_equal 3, existing_count

    post copy_schedule_link_availability_windows_path(@link), params: {
      source_link_id: link_two.id,
      mode: "replace"
    }

    assert_redirected_to schedule_link_availability_windows_path(@link, user_id: @user.id)

    # Should now have 2 windows (copied from link two), not 3 + 2
    assert_equal 2, @link.availability_windows.where(user: @user).count
  end

  test "copy merge mode adds windows without duplicating overlapping" do
    link_two = schedule_links(:two)

    # Link one has windows on day 0 (14:00-17:00, 18:00-22:00 UTC) and day 2 (14:00-22:00 UTC)
    # Link two has windows on day 0 (08:00-11:00 UTC) and day 1 (10:00-16:00 UTC)
    # Day 0 from link two (08:00-11:00) does not overlap with link one day 0 in UTC, so it is copied
    # Day 1 from link two (10:00-16:00) does not overlap with anything on link one, so it is copied

    initial_count = @link.availability_windows.where(user: @user).count
    assert_equal 3, initial_count

    post copy_schedule_link_availability_windows_path(@link), params: {
      source_link_id: link_two.id,
      mode: "merge"
    }

    assert_redirected_to schedule_link_availability_windows_path(@link, user_id: @user.id)

    # Should have 3 original + 2 new (both day 0 and day 1 from link two)
    assert_equal 5, @link.availability_windows.where(user: @user).count
  end

  test "cannot copy from a link user is not a member of" do
    # Create a link that user one is NOT a member of
    other_link = ScheduleLink.create!(
      name: "Secret", meeting_name: "Secret Call",
      meeting_duration_minutes: 30, meeting_location_type: "link",
      timezone: "Etc/UTC", buffer_minutes: 0, max_future_days: 30,
      created_by: users(:two)
    )

    post copy_schedule_link_availability_windows_path(@link), params: {
      source_link_id: other_link.id,
      mode: "replace"
    }

    assert_response :not_found
  end
end
