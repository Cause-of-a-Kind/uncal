class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :schedule_link, null: false, foreign_key: true
      t.references :contact, foreign_key: true
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.string :invitee_name, null: false
      t.string :invitee_email, null: false
      t.string :invitee_timezone, null: false
      t.text :invitee_notes
      t.string :status, null: false, default: "confirmed"
      t.string :google_event_id

      t.timestamps
    end

    add_index :bookings, [ :schedule_link_id, :start_time ]
    add_index :bookings, [ :schedule_link_id, :start_time, :status ], unique: true
  end
end
