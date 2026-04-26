# frozen_string_literal: true

class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.string   :legal_name,   null: false
      t.string   :display_name, null: false
      t.datetime :discarded_at
      t.datetime :deactivated_at
      t.bigint   :created_by_id
      t.bigint   :updated_by_id
      t.bigint   :deactivated_by_id

      t.timestamps
    end

    add_index :clients, :discarded_at
    add_index :clients, %i[discarded_at updated_at]
    add_index :clients, 'lower(legal_name)',
              name:   'index_clients_on_lower_legal_name',
              unique: true

    add_foreign_key :clients, :users, column: :created_by_id
    add_foreign_key :clients, :users, column: :updated_by_id
    add_foreign_key :clients, :users, column: :deactivated_by_id
  end
end
