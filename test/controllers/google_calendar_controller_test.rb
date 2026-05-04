require "test_helper"

class GoogleCalendarControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "GET /google_calendar/connect requires authentication" do
    get connect_google_calendar_path
    assert_redirected_to new_session_path
  end

  test "GET /google_calendar/connect redirects to Google OAuth URL with correct scopes" do
    sign_in_as @user
    get connect_google_calendar_path

    assert_response :redirect
    redirect_url = URI.parse(response.location)

    assert_equal "accounts.google.com", redirect_url.host
    assert_equal "/o/oauth2/v2/auth", redirect_url.path

    params = Rack::Utils.parse_query(redirect_url.query)
    assert_equal "code", params["response_type"]
    assert_includes params["scope"], "calendar.readonly"
    assert_includes params["scope"], "calendar.events"
    assert_equal callback_google_calendar_url, params["redirect_uri"]
  end

  test "GET /google_calendar/callback stores tokens on current user" do
    sign_in_as @user

    stub_token_exchange do
      get callback_google_calendar_path, params: { code: "test-auth-code" }
    end

    @user.reload
    assert_equal "ya29.test-access-token", @user.google_calendar_token
    assert_equal "1//test-refresh-token", @user.google_calendar_refresh_token
    assert_equal 1, @user.google_calendar_connections.active.count
  end

  test "GET /google_calendar/callback sets google_calendar_connected to true" do
    sign_in_as @user

    stub_token_exchange do
      get callback_google_calendar_path, params: { code: "test-auth-code" }
    end

    assert @user.reload.google_calendar_connected
  end

  test "GET /google_calendar/callback redirects to settings with success flash" do
    sign_in_as @user

    stub_token_exchange do
      get callback_google_calendar_path, params: { code: "test-auth-code" }
    end

    assert_redirected_to edit_settings_path
    assert_equal "Google Calendar connected successfully.", flash[:notice]
  end

  test "DELETE /google_calendar/disconnect clears all token fields" do
    sign_in_as @user
    @user.update!(
      google_calendar_token: "some-token",
      google_calendar_refresh_token: "some-refresh",
      google_calendar_token_expires_at: 1.hour.from_now,
      google_calendar_connected: true
    )

    delete disconnect_google_calendar_path

    @user.reload
    assert_nil @user.google_calendar_token
    assert_nil @user.google_calendar_refresh_token
    assert_nil @user.google_calendar_token_expires_at
  end

  test "DELETE /google_calendar/disconnect sets google_calendar_connected to false" do
    sign_in_as @user
    @user.update!(google_calendar_connected: true, google_calendar_token: "tok")

    delete disconnect_google_calendar_path

    assert_not @user.reload.google_calendar_connected
    assert_redirected_to edit_settings_path
    assert_equal "Google Calendar disconnected.", flash[:notice]
  end

  test "GET /google_calendar_connections/callback adds another connection without overwriting primary" do
    sign_in_as @user
    primary = @user.google_calendar_connections.create!(
      account_email: "primary@example.com",
      access_token: "primary-access",
      refresh_token: "primary-refresh",
      token_expires_at: 1.hour.from_now
    )

    stub_token_exchange do
      stub_primary_calendar_metadata("customer@example.com") do
        get callback_google_calendar_connections_path, params: { code: "test-auth-code" }
      end
    end

    assert_redirected_to edit_settings_path
    assert_equal 2, @user.google_calendar_connections.active.count
    assert primary.reload.primary?
    assert @user.google_calendar_connections.active.exists?(account_email: "customer@example.com", primary: false)
  end

  test "GET /google_calendar_connections/callback updates duplicate account connection" do
    sign_in_as @user
    existing = @user.google_calendar_connections.create!(
      account_email: "customer@example.com",
      access_token: "old-access",
      refresh_token: "old-refresh",
      token_expires_at: 5.minutes.ago
    )

    stub_token_exchange do
      stub_primary_calendar_metadata("customer@example.com") do
        get callback_google_calendar_connections_path, params: { code: "test-auth-code" }
      end
    end

    assert_equal 1, @user.google_calendar_connections.active.count
    assert_equal "ya29.test-access-token", existing.reload.access_token
  end

  private

  def stub_token_exchange(&block)
    mock_response_body = {
      "access_token" => "ya29.test-access-token",
      "refresh_token" => "1//test-refresh-token",
      "expires_in" => 3600,
      "token_type" => "Bearer"
    }.to_json

    fake_response = Data.define(:body).new(body: mock_response_body)

    original_method = Net::HTTP.method(:post_form)
    Net::HTTP.define_singleton_method(:post_form) { |*_args| fake_response }
    yield
  ensure
    Net::HTTP.define_singleton_method(:post_form, original_method)
  end

  def stub_primary_calendar_metadata(email)
    service_mock = Object.new
    service_mock.define_singleton_method(:authorization=) { |_auth| }
    service_mock.define_singleton_method(:get_calendar) do |_calendar_id|
      Google::Apis::CalendarV3::Calendar.new(id: email, summary: email)
    end

    original_new = Google::Apis::CalendarV3::CalendarService.method(:new)
    Google::Apis::CalendarV3::CalendarService.define_singleton_method(:new) { |*_args| service_mock }
    yield
  ensure
    Google::Apis::CalendarV3::CalendarService.define_singleton_method(:new, original_new)
  end
end
