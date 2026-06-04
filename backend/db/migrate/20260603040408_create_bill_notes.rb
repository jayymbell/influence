class CreateBillNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :bill_notes do |t|
      t.references :bill, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :content

      t.timestamps
    end
  end
end
