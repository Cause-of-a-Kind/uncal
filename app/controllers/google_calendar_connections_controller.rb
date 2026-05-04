class GoogleCalendarConnectionsController < ApplicationController
  before_action :require_authentication

  SCOPES = [
    "https://www.googleapis.com/auth/calendar.readonly",
    "https://www.googleapis.com/auth/calendar.events"
  ].freeze

  def connect
    params = {
      client_id: google_client_id,
      redirect_uri: callback_google_calendar_connections_url,
      response_type: "code",
      scope: SCOPES.join(" "),
      access_type: "offline",
      prompt: "consent"
    }

    redirect_to "https://accounts.google.com/o/oauth2/v2/auth?#{params.to_query}", allow_other_host: true
  end

  def callback
    if params[:code].blank?
      redirect_to edit_settings_path, alert: "Google Calendar connection failed."
      return
    end

    token_data = exchange_code_for_tokens(params[:code])
    metadata = primary_calendar_metadata(token_data["access_token"])
    connection = upsert_connection!(token_data, metadata)

    sync_legacy_user_fields!(connection)
    redirect_to edit_settings_path, notice: "Google Calendar connected successfully."
  rescue StandardError => e
    Rails.logger.error "Google Calendar OAuth error: #{e.message}"
    redirect_to edit_settings_path, alert: "Google Calendar connection failed."
  end

  def destroy
    connection = Current.user.google_calendar_connections.active.find(params[:id])
    was_primary = connection.primary?
    connection.disconnect!
    sync_legacy_user_fields!(Current.user.primary_google_calendar_connection) if was_primary

    redirect_to edit_settings_path, notice: "Google Calendar disconnected."
  end

  def disconnect
    Current.user.google_calendar_connections.active.find_each(&:disconnect!)
    Current.user.update!(
      google_calendar_token: nil,
      google_calendar_refresh_token: nil,
      google_calendar_token_expires_at: nil,
      google_calendar_connected: false
    )

    redirect_to edit_settings_path, notice: "Google Calendar disconnected."
  end

  private

  def upsert_connection!(token_data, metadata)
    account_email = metadata[:account_email].presence
    existing = account_email && Current.user.google_calendar_connections.active.find_by(account_email: account_email)
    existing ||= Current.user.primary_google_calendar_connection if Current.user.google_calendar_connections.active.empty?

    attrs = {
      access_token: token_data["access_token"],
      refresh_token: token_data["refresh_token"].presence || existing&.refresh_token,
      token_expires_at: Time.current + token_data["expires_in"].to_i.seconds,
      calendar_id: metadata[:id].presence || "primary",
      account_email: account_email,
      label: metadata[:summary].presence || account_email,
      revoked_at: nil,
      last_error: nil
    }

    if existing
      existing.update!(attrs)
      existing
    else
      Current.user.google_calendar_connections.create!(attrs)
    end
  end

  def sync_legacy_user_fields!(connection)
    if connection
      Current.user.update!(
        google_calendar_token: connection.access_token,
        google_calendar_refresh_token: connection.refresh_token,
        google_calendar_token_expires_at: connection.token_expires_at,
        google_calendar_connected: true
      )
    else
      Current.user.update!(
        google_calendar_token: nil,
        google_calendar_refresh_token: nil,
        google_calendar_token_expires_at: nil,
        google_calendar_connected: false
      )
    end
  end

  def primary_calendar_metadata(access_token)
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = access_token
    calendar = service.get_calendar("primary")

    {
      id: calendar.id.presence || "primary",
      summary: calendar.summary,
      account_email: calendar.id.to_s.include?("@") ? calendar.id : calendar.summary
    }
  rescue => e
    Rails.logger.error "Failed to fetch GCal primary calendar metadata: #{e.message}"
    { id: "primary" }
  end

  def google_client_id
    Rails.application.credentials.dig(:google, :client_id)
  end

  def google_client_secret
    Rails.application.credentials.dig(:google, :client_secret)
  end

  def exchange_code_for_tokens(code)
    response = Net::HTTP.post_form(
      URI("https://oauth2.googleapis.com/token"),
      code: code,
      client_id: google_client_id,
      client_secret: google_client_secret,
      redirect_uri: callback_google_calendar_connections_url,
      grant_type: "authorization_code"
    )

    JSON.parse(response.body)
  end
end
