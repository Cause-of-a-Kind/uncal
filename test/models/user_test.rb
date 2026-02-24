require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "google_calendar_token is encrypted" do
    user = users(:one)
    user.update!(google_calendar_token: "test-token-123")

    raw_value = ActiveRecord::Base.connection.select_value(
      "SELECT google_calendar_token FROM users WHERE id = #{user.id}"
    )

    assert_not_equal "test-token-123", raw_value
    assert_equal "test-token-123", user.reload.google_calendar_token
  end

  test "google_calendar_refresh_token is encrypted" do
    user = users(:one)
    user.update!(google_calendar_refresh_token: "refresh-token-456")

    raw_value = ActiveRecord::Base.connection.select_value(
      "SELECT google_calendar_refresh_token FROM users WHERE id = #{user.id}"
    )

    assert_not_equal "refresh-token-456", raw_value
    assert_equal "refresh-token-456", user.reload.google_calendar_refresh_token
  end

  test "google_calendar_connected defaults to false" do
    user = users(:one)
    assert_equal false, user.google_calendar_connected
  end

  test "google_calendar_token_expires_at is a datetime field" do
    user = users(:one)
    expires_at = 1.hour.from_now
    user.update!(google_calendar_token_expires_at: expires_at)
    assert_in_delta expires_at, user.reload.google_calendar_token_expires_at, 1.second
  end
end
