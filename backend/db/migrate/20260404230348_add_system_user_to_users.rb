class AddSystemUserToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :system_user, :boolean, default: false, null: false
    add_index :users, :system_user
  end
end
