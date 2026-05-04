class BackfillGoogleCalendarConnections < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  class MigrationGoogleCalendarConnection < ApplicationRecord
    self.table_name = "google_calendar_connections"
  end

  def up
    MigrationUser.where(google_calendar_connected: true).find_each do |user|
      next if user.google_calendar_refresh_token.blank?

      MigrationGoogleCalendarConnection.create!(
        user_id: user.id,
        access_token: user.google_calendar_token,
        refresh_token: user.google_calendar_refresh_token,
        token_expires_at: user.google_calendar_token_expires_at,
        primary: true,
        calendar_id: "primary",
        label: "Primary Google Calendar",
        created_at: Time.current,
        updated_at: Time.current
      )
    end
  end

  def down
    MigrationGoogleCalendarConnection.delete_all
  end
end
