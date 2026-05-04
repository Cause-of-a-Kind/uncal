class GoogleCalendarController < GoogleCalendarConnectionsController
  def connect
    params = {
      client_id: google_client_id,
      redirect_uri: callback_google_calendar_url,
      response_type: "code",
      scope: self.class::SCOPES.join(" "),
      access_type: "offline",
      prompt: "consent"
    }

    redirect_to "https://accounts.google.com/o/oauth2/v2/auth?#{params.to_query}", allow_other_host: true
  end

  private

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
