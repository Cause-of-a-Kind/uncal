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
