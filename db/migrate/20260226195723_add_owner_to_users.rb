class AddOwnerToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :owner, :boolean, default: false, null: false
  end
end
