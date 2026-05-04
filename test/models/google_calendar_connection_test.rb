require "test_helper"

class GoogleCalendarConnectionTest < ActiveSupport::TestCase
  test "tokens are encrypted" do
    connection = users(:one).google_calendar_connections.create!(
      access_token: "access-token-123",
      refresh_token: "refresh-token-456",
      token_expires_at: 1.hour.from_now
    )

    raw = ActiveRecord::Base.connection.select_value(
      "SELECT access_token FROM google_calendar_connections WHERE id = #{connection.id}"
    )

    refute_equal "access-token-123", raw
    assert_equal "access-token-123", connection.reload.access_token
  end

  test "first active connection becomes primary" do
    connection = users(:one).google_calendar_connections.create!(
      access_token: "access",
      refresh_token: "refresh",
      token_expires_at: 1.hour.from_now
    )

    assert connection.primary?
  end

  test "only one active primary connection is allowed per user" do
    user = users(:one)
    user.google_calendar_connections.create!(
      access_token: "access-one",
      refresh_token: "refresh-one",
      token_expires_at: 1.hour.from_now,
      primary: true
    )

    duplicate = user.google_calendar_connections.build(
      access_token: "access-two",
      refresh_token: "refresh-two",
      token_expires_at: 1.hour.from_now,
      primary: true
    )

    assert_not duplicate.valid?
  end

  test "disconnect promotes oldest remaining active connection" do
    user = users(:one)
    primary = user.google_calendar_connections.create!(
      access_token: "access-one",
      refresh_token: "refresh-one",
      token_expires_at: 1.hour.from_now,
      primary: true
    )
    secondary = user.google_calendar_connections.create!(
      access_token: "access-two",
      refresh_token: "refresh-two",
      token_expires_at: 1.hour.from_now,
      primary: false
    )

    primary.disconnect!

    assert secondary.reload.primary?
  end
end
