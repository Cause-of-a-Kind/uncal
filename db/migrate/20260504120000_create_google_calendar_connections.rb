class CreateGoogleCalendarConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :google_calendar_connections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :account_email
      t.string :label
      t.string :calendar_id, null: false, default: "primary"
      t.string :access_token
      t.string :refresh_token
      t.datetime :token_expires_at
      t.boolean :primary, null: false, default: false
      t.datetime :revoked_at
      t.string :last_error

      t.timestamps
    end

    add_index :google_calendar_connections, [ :user_id, :primary ],
      unique: true,
      where: "\"primary\" = 1 AND revoked_at IS NULL",
      name: "idx_gcal_connections_one_primary_per_user"
    add_index :google_calendar_connections, [ :user_id, :account_email ],
      unique: true,
      where: "account_email IS NOT NULL AND revoked_at IS NULL",
      name: "idx_gcal_connections_unique_account"
  end
end
