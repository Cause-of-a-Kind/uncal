class AddDescriptionToScheduleLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :schedule_links, :description, :text
  end
end
