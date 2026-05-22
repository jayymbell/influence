# frozen_string_literal: true

class CreateIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :issues do |t|
      t.string   :title,       null: false
      t.text     :description
      t.text     :notes
      t.string   :tags,        array: true, default: []
      t.integer  :status,      null: false, default: 0
      t.bigint   :client_id,   null: false
      t.datetime :closed_at
      t.bigint   :closed_by_id
      t.bigint   :created_by_id
      t.bigint   :updated_by_id

      t.timestamps
    end

    add_index :issues, :client_id
    add_index :issues, :status
    add_index :issues, %i[client_id status]
    add_index :issues, :tags, using: :gin

    add_foreign_key :issues, :clients, column: :client_id
    add_foreign_key :issues, :users,   column: :closed_by_id
    add_foreign_key :issues, :users,   column: :created_by_id
    add_foreign_key :issues, :users,   column: :updated_by_id
  end
end
