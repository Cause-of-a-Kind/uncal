class CreateAvailabilityWindows < ActiveRecord::Migration[8.1]
  def change
    create_table :availability_windows do |t|
      t.references :schedule_link, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :day_of_week, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.timestamps
    end

    add_index :availability_windows, [ :schedule_link_id, :user_id, :day_of_week ],
              name: "idx_availability_windows_link_user_day"
  end
end
