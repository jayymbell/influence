# frozen_string_literal: true

class CreateClientIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :client_issues do |t|
      t.bigint   :client_id,    null: false
      t.bigint   :issue_id,     null: false
      t.boolean  :is_primary,   null: false, default: false
      t.bigint   :shared_by_id
      t.datetime :shared_at

      t.timestamps
    end

    add_index :client_issues, %i[client_id issue_id], unique: true
    add_index :client_issues, :issue_id
    add_index :client_issues, :client_id

    add_foreign_key :client_issues, :clients, column: :client_id
    add_foreign_key :client_issues, :issues,  column: :issue_id
    add_foreign_key :client_issues, :users,   column: :shared_by_id
  end
end
