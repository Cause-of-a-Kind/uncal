require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "shows dashboard when authenticated" do
    sign_in_as users(:one)
    get root_path
    assert_response :success
    assert_select "h1", "Dashboard"
  end

  test "sign_up is not routable" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/sign_up", method: :get)
    end
  end
end
