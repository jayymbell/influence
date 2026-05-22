# frozen_string_literal: true

class CreateIssuePeople < ActiveRecord::Migration[8.0]
  def change
    create_table :issue_people do |t|
      t.bigint :issue_id,    null: false
      t.bigint :person_id,   null: false
      t.bigint :added_by_id

      t.timestamps
    end

    add_index :issue_people, %i[issue_id person_id], unique: true
    add_index :issue_people, :issue_id
    add_index :issue_people, :person_id

    add_foreign_key :issue_people, :issues,  column: :issue_id
    add_foreign_key :issue_people, :people,  column: :person_id
    add_foreign_key :issue_people, :users,   column: :added_by_id
  end
end
