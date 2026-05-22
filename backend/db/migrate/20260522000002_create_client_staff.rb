class CreateClientStaff < ActiveRecord::Migration[8.0]
  def change
    create_table :client_staff do |t|
      t.references :client, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :client_staff, [:client_id, :user_id], unique: true
  end
end
