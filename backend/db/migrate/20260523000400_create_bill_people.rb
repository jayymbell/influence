# frozen_string_literal: true

class CreateBillPeople < ActiveRecord::Migration[8.0]
  def change
    create_table :bill_people do |t|
      t.bigint :bill_id,     null: false
      t.bigint :person_id,   null: false
      t.bigint :added_by_id

      t.timestamps
    end

    add_index :bill_people, %i[bill_id person_id], unique: true
    add_index :bill_people, :person_id

    add_foreign_key :bill_people, :bills,   column: :bill_id
    add_foreign_key :bill_people, :people,  column: :person_id
    add_foreign_key :bill_people, :users,   column: :added_by_id
  end
end
