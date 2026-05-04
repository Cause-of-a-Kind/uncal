class CreateGoogleCalendarEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :google_calendar_events do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :google_calendar_connection, null: false, foreign_key: true
      t.string :google_event_id, null: false

      t.timestamps
    end

    add_index :google_calendar_events,
      [ :booking_id, :google_calendar_connection_id ],
      unique: true,
      name: "idx_gcal_events_unique_booking_connection"
  end
end
