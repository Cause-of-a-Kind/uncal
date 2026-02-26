require "test_helper"

module Admin
  class BookingsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      sign_in_as @user
    end

    test "index requires authentication" do
      sign_out
      get admin_bookings_path
      assert_redirected_to new_session_path
    end

    test "index lists bookings for current user's schedule links" do
      get admin_bookings_path
      assert_response :success
      assert_match bookings(:confirmed_one).invitee_name, response.body
    end

    test "index shows empty state when no bookings" do
      Booking.destroy_all
      get admin_bookings_path
      assert_response :success
      assert_match "No bookings yet", response.body
    end

    test "show displays booking details" do
      booking = bookings(:confirmed_one)
      get admin_booking_path(booking)
      assert_response :success
      assert_match booking.invitee_name, response.body
      assert_match booking.invitee_email, response.body
    end

    test "show returns 404 for booking on unrelated link" do
      other_link = ScheduleLink.create!(
        name: "Private", meeting_name: "Private Call",
        meeting_duration_minutes: 30, meeting_location_type: "link",
        timezone: "Etc/UTC", buffer_minutes: 0, max_future_days: 30,
        created_by: users(:two)
      )
      booking = other_link.bookings.create!(
        start_time: 1.day.from_now, end_time: 1.day.from_now + 30.minutes,
        invitee_name: "Secret", invitee_email: "s@s.com", invitee_timezone: "Etc/UTC"
      )

      get admin_booking_path(booking)
      assert_response :not_found
    end

    # Filter tests
    test "filter by schedule link" do
      link = schedule_links(:one)
      get admin_bookings_path, params: { schedule_link_id: link.id }
      assert_response :success
      assert_match bookings(:confirmed_one).invitee_name, response.body
    end

    test "filter by status confirmed" do
      get admin_bookings_path, params: { status: "confirmed" }
      assert_response :success
      assert_match bookings(:confirmed_one).invitee_name, response.body
      assert_no_match bookings(:cancelled_one).invitee_name, response.body
    end

    test "filter by status cancelled" do
      get admin_bookings_path, params: { status: "cancelled" }
      assert_response :success
      assert_match bookings(:cancelled_one).invitee_name, response.body
      assert_no_match bookings(:confirmed_one).invitee_name, response.body
    end

    test "filter by date range" do
      booking = bookings(:confirmed_one)
      from_date = booking.start_time.to_date.to_s
      to_date = booking.start_time.to_date.to_s
      get admin_bookings_path, params: { from: from_date, to: to_date }
      assert_response :success
      assert_match booking.invitee_name, response.body
    end

    # Cancel tests
    test "cancel sets booking status to cancelled" do
      booking = bookings(:upcoming_one)
      patch cancel_admin_booking_path(booking)
      assert_redirected_to admin_booking_path(booking)
      assert_equal "cancelled", booking.reload.status
    end

    test "cancel sends cancellation email" do
      booking = bookings(:upcoming_one)
      assert_enqueued_email_with BookingMailer, :cancellation, args: [ booking ] do
        patch cancel_admin_booking_path(booking)
      end
    end

    test "cancel already cancelled booking redirects with notice" do
      booking = bookings(:cancelled_one)
      patch cancel_admin_booking_path(booking)
      assert_redirected_to admin_booking_path(booking)
      follow_redirect!
      assert_match "already cancelled", response.body
    end

    test "cancel requires authentication" do
      sign_out
      patch cancel_admin_booking_path(bookings(:upcoming_one))
      assert_redirected_to new_session_path
    end
  end
end
