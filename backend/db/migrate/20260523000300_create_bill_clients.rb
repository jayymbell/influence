# frozen_string_literal: true

class CreateBillClients < ActiveRecord::Migration[8.0]
  def change
    create_table :bill_clients do |t|
      t.bigint   :bill_id,      null: false
      t.bigint   :client_id,    null: false
      t.bigint   :shared_by_id
      t.datetime :shared_at

      t.timestamps
    end

    add_index :bill_clients, %i[bill_id client_id], unique: true
    add_index :bill_clients, :client_id

    add_foreign_key :bill_clients, :bills,   column: :bill_id
    add_foreign_key :bill_clients, :clients, column: :client_id
    add_foreign_key :bill_clients, :users,   column: :shared_by_id
  end
end
