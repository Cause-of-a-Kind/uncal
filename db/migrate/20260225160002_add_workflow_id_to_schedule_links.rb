class AddWorkflowIdToScheduleLinks < ActiveRecord::Migration[8.1]
  def change
    add_reference :schedule_links, :workflow, null: true, foreign_key: true
  end
end
