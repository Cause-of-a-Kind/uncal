class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.text :notes
      t.datetime :last_booked_at
      t.integer :total_bookings_count, default: 0, null: false

      t.timestamps
    end

    add_index :contacts, [ :user_id, :email ], unique: true
    add_index :contacts, [ :user_id, :last_booked_at ]
  end
end
