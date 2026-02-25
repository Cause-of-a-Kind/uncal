class CreateWorkflowSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :workflow_steps do |t|
      t.references :workflow, null: false, foreign_key: true
      t.string :timing_direction, null: false
      t.integer :timing_minutes, null: false
      t.string :email_subject, null: false
      t.text :email_body, null: false
      t.string :recipient_type, null: false, default: "invitee"
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :workflow_steps, [ :workflow_id, :position ]
  end
end
