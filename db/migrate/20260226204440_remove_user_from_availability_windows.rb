class RemoveUserFromAvailabilityWindows < ActiveRecord::Migration[8.1]
  def change
    remove_index :availability_windows, name: "idx_availability_windows_link_user_day"
    remove_index :availability_windows, :user_id
    remove_foreign_key :availability_windows, :users
    remove_column :availability_windows, :user_id, :integer, null: false
    add_index :availability_windows, [:schedule_link_id, :day_of_week], name: "idx_availability_windows_link_day"
  end
end
