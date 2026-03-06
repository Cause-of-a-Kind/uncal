require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "requires authentication" do
    sign_out
    get root_path
    assert_redirected_to new_session_path
  end

  test "shows dashboard when authenticated" do
    get root_path
    assert_response :success
    assert_select "h1", "Dashboard"
  end

  test "sign_up is not routable" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/sign_up", method: :get)
    end
  end

  test "shows bookings this week count" do
    get dashboard_path
    assert_response :success
    assert_match "Bookings this week", response.body
  end

  test "shows schedule links count" do
    get dashboard_path
    assert_response :success
    assert_match "Schedule links", response.body
    assert_match @user.schedule_links.count.to_s, response.body
  end

  test "shows upcoming bookings section" do
    get dashboard_path
    assert_response :success
    assert_match bookings(:upcoming_one).invitee_name, response.body
  end

  test "shows recent bookings section" do
    get dashboard_path
    assert_response :success
    assert_match bookings(:recent_one).invitee_name, response.body
  end

  test "upcoming bookings includes bookings beyond 7 days" do
    # Create a booking 20 days from now — should still appear
    far_booking = Booking.create!(
      schedule_link: schedule_links(:one),
      start_time: 20.days.from_now.utc.beginning_of_hour,
      end_time: 20.days.from_now.utc.beginning_of_hour + 30.minutes,
      invitee_name: "Far Future",
      invitee_email: "far@example.com",
      invitee_timezone: "America/New_York",
      status: "confirmed"
    )

    get dashboard_path
    assert_response :success
    assert_match "Far Future", response.body
  end

  test "recent bookings includes bookings older than 7 days" do
    get dashboard_path
    assert_response :success
    # old_one fixture is 120 days ago
    assert_match bookings(:old_one).invitee_name, response.body
  end

  test "shows empty state when no upcoming bookings" do
    Booking.where("start_time >= ?", Time.current).destroy_all
    get dashboard_path
    assert_response :success
    assert_match "No upcoming bookings", response.body
  end

  test "shows link to create new schedule link" do
    get dashboard_path
    assert_response :success
    assert_select "a[href=?]", new_schedule_link_path
  end
end
