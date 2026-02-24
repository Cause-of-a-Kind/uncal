class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :timezone, null: false, default: "Etc/UTC"
      t.string :google_calendar_token
      t.string :google_calendar_refresh_token
      t.datetime :google_calendar_token_expires_at
      t.boolean :google_calendar_connected, null: false, default: false

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
