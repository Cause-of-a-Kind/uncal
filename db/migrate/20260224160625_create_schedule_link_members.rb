class CreateScheduleLinkMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_link_members do |t|
      t.references :schedule_link, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :schedule_link_members, [ :schedule_link_id, :user_id ], unique: true
  end
end
