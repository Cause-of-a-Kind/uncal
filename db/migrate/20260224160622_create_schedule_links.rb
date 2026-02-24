class CreateScheduleLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_links do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.string :meeting_name, null: false
      t.integer :meeting_duration_minutes, null: false
      t.string :meeting_location_type, null: false
      t.string :meeting_location_value
      t.string :timezone, null: false
      t.integer :buffer_minutes, null: false, default: 0
      t.integer :max_bookings_per_day
      t.integer :max_future_days, null: false, default: 30
      t.string :status, null: false, default: "active"
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :schedule_links, :slug, unique: true
    add_index :schedule_links, :status
  end
end
