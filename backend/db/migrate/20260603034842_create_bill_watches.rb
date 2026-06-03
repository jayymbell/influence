class CreateBillWatches < ActiveRecord::Migration[8.0]
  def change
    create_table :bill_watches do |t|
      t.references :user, null: false, foreign_key: true
      t.references :bill, null: false, foreign_key: true

      t.timestamps
    end

    add_index :bill_watches, [:user_id, :bill_id], unique: true
  end
end
