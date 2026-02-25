class CreateWorkflows < ActiveRecord::Migration[8.1]
  def change
    create_table :workflows do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :state, null: false, default: "active"

      t.timestamps
    end

    add_index :workflows, [ :user_id, :state ]
  end
end
