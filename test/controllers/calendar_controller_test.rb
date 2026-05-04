require "test_helper"

class CalendarControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @connection = @user.google_calendar_connections.create!(
      account_email: "one.customer@example.com",
      access_token: "access",
      refresh_token: "refresh",
      token_expires_at: 1.hour.from_now
    )
  end

  test "calendar requires authentication" do
    get calendar_path
    assert_redirected_to new_session_path
  end

  test "calendar shows selected user's busy blocks without event details" do
    sign_in_as @user

    with_fake_calendar_service do
      get calendar_path, params: { user_id: @user.id, week: "2026-03-02" }
    end

    assert_response :success
    assert_match "Busy", response.body
    assert_match "one.customer@example.com", response.body
    assert_no_match "Customer Contract Review", response.body
  end

  private

  def with_fake_calendar_service
    original_new = GoogleCalendarService.method(:new)
    service = fake_calendar_service
    GoogleCalendarService.define_singleton_method(:new) { |*_args| service }
    yield
  ensure
    GoogleCalendarService.define_singleton_method(:new, original_new)
  end

  def fake_calendar_service
    service = Object.new
    service.define_singleton_method(:busy_times) do |_start_date, _end_date|
      [
        {
          start: Time.utc(2026, 3, 2, 15, 0),
          end: Time.utc(2026, 3, 2, 16, 0),
          title: "Customer Contract Review"
        }
      ]
    end
    service
  end
end
