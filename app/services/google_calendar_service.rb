class GoogleCalendarService
  class NotConnectedError < StandardError; end
  class ApiError < StandardError; end
  class TokenRevokedError < StandardError; end

  TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token"

  def initialize(user)
    @user = user
  end

  def busy_times(start_date, end_date)
    ensure_connected!

    cache_key = "gcal_busy/#{@user.id}/#{start_date}/#{end_date}"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      refresh_token_if_needed!

      request = Google::Apis::CalendarV3::FreeBusyRequest.new(
        time_min: start_date.beginning_of_day.utc.iso8601,
        time_max: end_date.end_of_day.utc.iso8601,
        items: [ { id: "primary" } ]
      )

      response = client.query_freebusy(request)
      calendar = response.calendars["primary"]

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

  def self.invalidate_busy_cache(user, date)
    Rails.cache.delete("gcal_busy/#{user.id}/#{date}/#{date}")
  end

  def create_event(title:, start_time:, end_time:, description: nil, location: nil)
    ensure_connected!

    refresh_token_if_needed!

    event = Google::Apis::CalendarV3::Event.new(
      summary: title,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_time.iso8601),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: end_time.iso8601),
      description: description,
      location: location
    )

    result = client.insert_event("primary", event)
    result.id
  rescue NotConnectedError, TokenRevokedError
    raise
  rescue => e
    raise ApiError, "Failed to create event: #{e.message}"
  end

  def delete_event(event_id)
    ensure_connected!
    refresh_token_if_needed!
    client.delete_event("primary", event_id)
  rescue NotConnectedError, TokenRevokedError
    raise
  rescue => e
    Rails.logger.error "Failed to delete GCal event: #{e.message}"
  end

  private

  def ensure_connected!
    raise NotConnectedError, "User has not connected Google Calendar" unless @user.google_calendar_connected?
  end

  def refresh_token_if_needed!
    return if @user.google_calendar_token_expires_at.present? && @user.google_calendar_token_expires_at > Time.current

    refresh_token!
  end

  def refresh_token!
    response = Net::HTTP.post_form(
      URI(TOKEN_ENDPOINT),
      client_id: google_client_id,
      client_secret: google_client_secret,
      refresh_token: @user.google_calendar_refresh_token,
      grant_type: "refresh_token"
    )

    data = JSON.parse(response.body)

    if response.code != "200" || data["error"].present?
      @user.update!(
        google_calendar_token: nil,
        google_calendar_refresh_token: nil,
        google_calendar_token_expires_at: nil,
        google_calendar_connected: false
      )
      raise TokenRevokedError, "Google Calendar access has been revoked"
    end

    @user.update!(
      google_calendar_token: data["access_token"],
      google_calendar_token_expires_at: Time.current + data["expires_in"].to_i.seconds
    )
  end

  def client
    @client ||= Google::Apis::CalendarV3::CalendarService.new.tap do |service|
      service.authorization = @user.google_calendar_token
    end
  end

  def google_client_id
    Rails.application.credentials.dig(:google, :client_id)
  end

  def google_client_secret
    Rails.application.credentials.dig(:google, :client_secret)
  end
end
