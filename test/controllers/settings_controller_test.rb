require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "edit requires authentication" do
    sign_out
    get edit_settings_path
    assert_redirected_to new_session_path
  end

  test "edit shows settings form" do
    get edit_settings_path
    assert_response :success
    assert_select "h1", "Settings"
  end

  test "update changes user profile" do
    patch settings_path, params: {
      user: { name: "Updated Name", timezone: "America/Chicago" }
    }
    assert_redirected_to edit_settings_path

    @user.reload
    assert_equal "Updated Name", @user.name
    assert_equal "America/Chicago", @user.timezone
  end

  test "update with invalid params renders errors" do
    patch settings_path, params: {
      user: { name: "" }
    }
    assert_response :unprocessable_entity
  end

  test "timezone is set from current user" do
    @user.update!(timezone: "America/New_York")

    get edit_settings_path
    assert_response :success
  end
end
