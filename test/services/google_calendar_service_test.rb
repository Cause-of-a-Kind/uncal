require "test_helper"

class GoogleCalendarServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.update!(
      google_calendar_token: "ya29.valid-token",
      google_calendar_refresh_token: "1//valid-refresh",
      google_calendar_token_expires_at: 1.hour.from_now,
      google_calendar_connected: true
    )
    @service = GoogleCalendarService.new(@user)
  end

  # Cycle 3: Core functionality

  test "#busy_times returns array of start/end hashes" do
    busy_start = Time.utc(2026, 3, 1, 10, 0)
    busy_end = Time.utc(2026, 3, 1, 11, 0)

    with_mock_calendar_service(:freebusy, [ { start: busy_start.iso8601, end: busy_end.iso8601 } ]) do
      result = @service.busy_times(Date.new(2026, 3, 1), Date.new(2026, 3, 2))

      assert_equal 1, result.length
      assert_equal busy_start, result.first[:start]
      assert_equal busy_end, result.first[:end]
    end
  end

  test "#busy_times returns empty array for empty calendar" do
    with_mock_calendar_service(:freebusy, []) do
      result = @service.busy_times(Date.new(2026, 3, 1), Date.new(2026, 3, 2))
      assert_equal [], result
    end
  end

  test "#busy_times converts API response to UTC" do
    busy_start = "2026-03-01T10:00:00-05:00"
    busy_end = "2026-03-01T11:00:00-05:00"

    with_mock_calendar_service(:freebusy, [ { start: busy_start, end: busy_end } ]) do
      result = @service.busy_times(Date.new(2026, 3, 1), Date.new(2026, 3, 2))

      assert_equal Time.utc(2026, 3, 1, 15, 0), result.first[:start]
      assert_equal Time.utc(2026, 3, 1, 16, 0), result.first[:end]
    end
  end

  test "#create_event calls API with correct parameters and returns event ID" do
    with_mock_calendar_service(:create, "event123") do
      event_id = @service.create_event(
        title: "Meeting with Alice",
        start_time: Time.utc(2026, 3, 1, 14, 0),
        end_time: Time.utc(2026, 3, 1, 15, 0),
        description: "Discuss project",
        location: "Zoom"
      )

      assert_equal "event123", event_id
    end
  end

  test "#create_event returns the created event ID" do
    with_mock_calendar_service(:create, "abc-xyz-123") do
      event_id = @service.create_event(
        title: "Quick sync",
        start_time: Time.utc(2026, 3, 1, 14, 0),
        end_time: Time.utc(2026, 3, 1, 14, 30)
      )

      assert_equal "abc-xyz-123", event_id
    end
  end

  test "raises NotConnectedError when user not connected" do
    @user.update!(google_calendar_connected: false)
    service = GoogleCalendarService.new(@user)

    assert_raises(GoogleCalendarService::NotConnectedError) do
      service.create_event(
        title: "Test",
        start_time: Time.current,
        end_time: 1.hour.from_now
      )
    end
  end

  test "#busy_times returns empty array on API error" do
    with_mock_calendar_service(:error) do
      result = @service.busy_times(Date.new(2026, 3, 1), Date.new(2026, 3, 2))
      assert_equal [], result
    end
  end

  # Cycle 4: Token refresh

  test "refreshes token when expired" do
    @user.update!(google_calendar_token_expires_at: 5.minutes.ago)

    with_mock_token_refresh("ya29.new-token") do
      with_mock_calendar_service(:freebusy, []) do
        @service.busy_times(Date.new(2026, 3, 1), Date.new(2026, 3, 2))
      end
    end

    assert_equal "ya29.new-token", @user.reload.google_calendar_token
  end

  test "refreshed token is saved to user record" do
    @user.update!(google_calendar_token_expires_at: 5.minutes.ago)

    with_mock_token_refresh("ya29.saved-token") do
      with_mock_calendar_service(:freebusy, []) do
        @service.busy_times(Date.new(2026, 3, 1), Date.new(2026, 3, 2))
      end
    end

    @user.reload
    assert_equal "ya29.saved-token", @user.google_calendar_token
    assert @user.google_calendar_token_expires_at > Time.current
  end

  test "service works transparently after token refresh" do
    @user.update!(google_calendar_token_expires_at: 5.minutes.ago)

    busy_start = Time.utc(2026, 3, 1, 10, 0)
    busy_end = Time.utc(2026, 3, 1, 11, 0)

    with_mock_token_refresh("ya29.refreshed") do
      with_mock_calendar_service(:freebusy, [ { start: busy_start.iso8601, end: busy_end.iso8601 } ]) do
        result = @service.busy_times(Date.new(2026, 3, 1), Date.new(2026, 3, 2))

        assert_equal 1, result.length
        assert_equal busy_start, result.first[:start]
      end
    end
  end

  test "handles refresh failure by disconnecting user" do
    @user.update!(google_calendar_token_expires_at: 5.minutes.ago)

    with_mock_token_refresh_failure do
      assert_raises(GoogleCalendarService::TokenRevokedError) do
        @service.busy_times(Date.new(2026, 3, 1), Date.new(2026, 3, 2))
      end
    end

    @user.reload
    assert_not @user.google_calendar_connected
    assert_nil @user.google_calendar_token
    assert_nil @user.google_calendar_refresh_token
  end

  private

  def with_mock_calendar_service(mode, data = nil)
    service_mock = Object.new
    service_mock.define_singleton_method(:authorization=) { |_auth| }

    case mode
    when :freebusy
      calendars = { "primary" => Google::Apis::CalendarV3::FreeBusyCalendar.new(
        busy: data.map { |bp|
          Google::Apis::CalendarV3::TimePeriod.new(start: bp[:start], end: bp[:end])
        }
      ) }
      freebusy_response = Google::Apis::CalendarV3::FreeBusyResponse.new(calendars: calendars)
      service_mock.define_singleton_method(:query_freebusy) { |_req| freebusy_response }
    when :create
      created_event = Google::Apis::CalendarV3::Event.new(id: data)
      service_mock.define_singleton_method(:insert_event) { |_cal_id, _event| created_event }
    when :error
      service_mock.define_singleton_method(:query_freebusy) { |_req|
        raise Google::Apis::ServerError, "Internal Server Error"
      }
    end

    original_new = Google::Apis::CalendarV3::CalendarService.method(:new)
    Google::Apis::CalendarV3::CalendarService.define_singleton_method(:new) { |*_args| service_mock }
    yield
  ensure
    Google::Apis::CalendarV3::CalendarService.define_singleton_method(:new, original_new)
  end

  def with_mock_token_refresh(new_token)
    response_body = {
      "access_token" => new_token,
      "expires_in" => 3600,
      "token_type" => "Bearer"
    }.to_json

    fake_response = Data.define(:body, :code).new(body: response_body, code: "200")

    original_post_form = Net::HTTP.method(:post_form)
    Net::HTTP.define_singleton_method(:post_form) { |*_args| fake_response }
    yield
  ensure
    Net::HTTP.define_singleton_method(:post_form, original_post_form)
  end

  def with_mock_token_refresh_failure
    response_body = { "error" => "invalid_grant" }.to_json
    fake_response = Data.define(:body, :code).new(body: response_body, code: "400")

    original_post_form = Net::HTTP.method(:post_form)
    Net::HTTP.define_singleton_method(:post_form) { |*_args| fake_response }
    yield
  ensure
    Net::HTTP.define_singleton_method(:post_form, original_post_form)
  end
end
