require "test_helper"

class LegalControllerTest < ActionDispatch::IntegrationTest
  test "privacy policy is public" do
    get privacy_path

    assert_response :success
    assert_select "h1", "Privacy Policy"
    assert_match "Google Calendar", response.body
  end
end
