class GoogleCalendarController < ApplicationController
  before_action :require_authentication

  SCOPES = [
    "https://www.googleapis.com/auth/calendar.readonly",
    "https://www.googleapis.com/auth/calendar.events"
  ].freeze

  def connect
    params = {
      client_id: google_client_id,
      redirect_uri: callback_google_calendar_url,
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

    Current.user.update!(
      google_calendar_token: token_data["access_token"],
      google_calendar_refresh_token: token_data["refresh_token"],
      google_calendar_token_expires_at: Time.current + token_data["expires_in"].to_i.seconds,
      google_calendar_connected: true
    )

    redirect_to edit_settings_path, notice: "Google Calendar connected successfully."
  rescue StandardError => e
    Rails.logger.error "Google Calendar OAuth error: #{e.message}"
    redirect_to edit_settings_path, alert: "Google Calendar connection failed."
  end

  def disconnect
    Current.user.update!(
      google_calendar_token: nil,
      google_calendar_refresh_token: nil,
      google_calendar_token_expires_at: nil,
      google_calendar_connected: false
    )

    redirect_to edit_settings_path, notice: "Google Calendar disconnected."
  end

  private

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
      redirect_uri: callback_google_calendar_url,
      grant_type: "authorization_code"
    )

    JSON.parse(response.body)
  end
end
