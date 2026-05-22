# frozen_string_literal: true

class AddClientIdToPeople < ActiveRecord::Migration[8.0]
  def change
    add_reference :people, :client, foreign_key: true, null: true
  end
end
