# frozen_string_literal: true

class CreateBills < ActiveRecord::Migration[8.0]
  def change
    create_table :bills do |t|
      t.string   :bill_number
      t.integer  :chamber
      t.integer  :session_year
      t.string   :title,            null: false
      t.text     :description
      t.text     :notes
      t.string   :tags,             array: true, default: []
      t.integer  :status,           null: false, default: 0
      t.bigint   :companion_bill_id
      t.string   :external_id
      t.string   :source_url
      t.datetime :last_synced_at
      t.bigint   :created_by_id
      t.bigint   :updated_by_id

      t.timestamps
    end

    add_index :bills, :status
    add_index :bills, :chamber
    add_index :bills, :session_year
    add_index :bills, :companion_bill_id
    add_index :bills, :external_id
    add_index :bills, :tags, using: :gin

    add_foreign_key :bills, :bills, column: :companion_bill_id
    add_foreign_key :bills, :users, column: :created_by_id
    add_foreign_key :bills, :users, column: :updated_by_id
  end
end
