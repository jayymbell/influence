# frozen_string_literal: true

class CreateBillIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :bill_issues do |t|
      t.bigint   :bill_id,      null: false
      t.bigint   :issue_id,     null: false
      t.bigint   :added_by_id
      t.datetime :added_at

      t.timestamps
    end

    add_index :bill_issues, %i[bill_id issue_id], unique: true
    add_index :bill_issues, :issue_id

    add_foreign_key :bill_issues, :bills,  column: :bill_id
    add_foreign_key :bill_issues, :issues, column: :issue_id
    add_foreign_key :bill_issues, :users,  column: :added_by_id
  end
end
