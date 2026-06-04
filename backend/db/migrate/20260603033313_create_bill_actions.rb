class CreateBillActions < ActiveRecord::Migration[8.0]
  def change
    create_table :bill_actions do |t|
      t.references :bill, null: false, foreign_key: true
      t.date :action_date, null: false
      t.text :description, null: false
      t.string :classification, array: true, default: []
      t.integer :action_order

      t.timestamps
    end

    add_index :bill_actions, [:bill_id, :action_date, :description],
              name: "index_bill_actions_uniqueness", unique: true
    add_index :bill_actions, [:bill_id, :action_order]
  end
end
