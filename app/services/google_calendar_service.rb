class GoogleCalendarService
  class NotConnectedError < StandardError; end
  class ApiError < StandardError; end
  class TokenRevokedError < StandardError; end

  TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token"

  def initialize(connection_or_user)
    @connection = connection_or_user if connection_or_user.is_a?(GoogleCalendarConnection)
    @user = @connection&.user || connection_or_user
  end

  def busy_times(start_date, end_date)
    ensure_connected!

    cache_key = "gcal_busy/#{cache_owner_key}/#{start_date}/#{end_date}"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      refresh_token_if_needed!

      request = Google::Apis::CalendarV3::FreeBusyRequest.new(
        time_min: start_date.beginning_of_day.utc.iso8601,
        time_max: end_date.end_of_day.utc.iso8601,
        items: [ { id: calendar_id } ]
      )

      response = client.query_freebusy(request)
      calendar = response.calendars[calendar_id]

      (calendar&.busy || []).map do |period|
        {
          start: Time.parse(period.start.to_s).utc,
          end: Time.parse(period.end.to_s).utc
        }
      end
    end
  rescue NotConnectedError, TokenRevokedError
    raise
  rescue => e
    Rails.logger.error "Google Calendar API error: #{e.message}"
    []
  end

  def self.invalidate_busy_cache(user_or_connection, date)
    if user_or_connection.is_a?(GoogleCalendarConnection)
      Rails.cache.delete("gcal_busy/connection:#{user_or_connection.id}/#{date}/#{date}")
    else
      user_or_connection.active_google_calendar_connections.each do |connection|
        Rails.cache.delete("gcal_busy/connection:#{connection.id}/#{date}/#{date}")
      end
      Rails.cache.delete("gcal_busy/user:#{user_or_connection.id}/#{date}/#{date}")
    end
  end

  def create_event(title:, start_time:, end_time:, description: nil, location: nil, add_conference: false, attendees: [])
    ensure_connected!

    refresh_token_if_needed!

    event = Google::Apis::CalendarV3::Event.new(
      summary: title,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_time.iso8601, time_zone: "UTC"),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: end_time.iso8601, time_zone: "UTC"),
      description: description,
      location: location
    )

    if add_conference
      event.conference_data = Google::Apis::CalendarV3::ConferenceData.new(
        create_request: Google::Apis::CalendarV3::CreateConferenceRequest.new(
          request_id: SecureRandom.uuid,
          conference_solution_key: Google::Apis::CalendarV3::ConferenceSolutionKey.new(type: "hangoutsMeet")
        )
      )
    end

    if attendees.any?
      event.attendees = attendees.map { |email| Google::Apis::CalendarV3::EventAttendee.new(email: email) }
    end

    result = client.insert_event(calendar_id, event, conference_data_version: add_conference ? 1 : 0, send_updates: "none")
    { event_id: result.id, meet_url: result.hangout_link }
  rescue NotConnectedError, TokenRevokedError
    raise
  rescue => e
    raise ApiError, "Failed to create event: #{e.message}"
  end

  def delete_event(event_id)
    ensure_connected!
    refresh_token_if_needed!
    client.delete_event(calendar_id, event_id, send_updates: "none")
  rescue NotConnectedError, TokenRevokedError
    raise
  rescue => e
    Rails.logger.error "Failed to delete GCal event: #{e.message}"
  end

  def primary_calendar_metadata
    ensure_connected!
    refresh_token_if_needed!

    calendar = client.get_calendar(calendar_id)
    {
      id: calendar.id,
      summary: calendar.summary,
      account_email: calendar.id.to_s.include?("@") ? calendar.id : calendar.summary
    }
  rescue => e
    Rails.logger.error "Failed to fetch GCal calendar metadata: #{e.message}"
    {}
  end

  private

  def ensure_connected!
    if @connection
      raise NotConnectedError, "Google Calendar connection is not active" unless @connection.active?
    else
      raise NotConnectedError, "User has not connected Google Calendar" unless @user.google_calendar_connected?
    end
  end

  def refresh_token_if_needed!
    return if token_expires_at.present? && token_expires_at > Time.current

    refresh_token!
  end

  def refresh_token!
    response = Net::HTTP.post_form(
      URI(TOKEN_ENDPOINT),
      client_id: google_client_id,
      client_secret: google_client_secret,
      refresh_token: refresh_token,
      grant_type: "refresh_token"
    )

    data = JSON.parse(response.body)

    if response.code != "200" || data["error"].present?
      disconnect_after_refresh_failure!
      raise TokenRevokedError, "Google Calendar access has been revoked"
    end

    update_tokens!(data["access_token"], Time.current + data["expires_in"].to_i.seconds)
  end

  def client
    @client ||= Google::Apis::CalendarV3::CalendarService.new.tap do |service|
      service.authorization = access_token
    end
  end

  def cache_owner_key
    @connection ? "connection:#{@connection.id}" : "user:#{@user.id}"
  end

  def calendar_id
    @connection&.calendar_id.presence || "primary"
  end

  def access_token
    @connection ? @connection.access_token : @user.google_calendar_token
  end

  def refresh_token
    @connection ? @connection.refresh_token : @user.google_calendar_refresh_token
  end

  def token_expires_at
    @connection ? @connection.token_expires_at : @user.google_calendar_token_expires_at
  end

  def update_tokens!(token, expires_at)
    if @connection
      @connection.update!(access_token: token, token_expires_at: expires_at, last_error: nil)
    else
      @user.update!(google_calendar_token: token, google_calendar_token_expires_at: expires_at)
    end
  end

  def disconnect_after_refresh_failure!
    if @connection
      @connection.update!(
        access_token: nil,
        refresh_token: nil,
        token_expires_at: nil,
        revoked_at: Time.current,
        primary: false,
        last_error: "Google Calendar access has been revoked"
      )
      @connection.user.promote_google_calendar_primary!
    else
      @user.update!(
        google_calendar_token: nil,
        google_calendar_refresh_token: nil,
        google_calendar_token_expires_at: nil,
        google_calendar_connected: false
      )
    end
  end

  def google_client_id
    Rails.application.credentials.dig(:google, :client_id)
  end

  def google_client_secret
    Rails.application.credentials.dig(:google, :client_secret)
  end
end
