class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.dig(:mailer, :from) || "noreply@example.com"
  layout "mailer"
end
