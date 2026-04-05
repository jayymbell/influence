class CreatePeople < ActiveRecord::Migration[8.0]
  def change
    create_table :people do |t|
      # Optional 1:1 link to an app user
      t.references :user, null: true, foreign_key: true

      # Required identity fields
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :display_name, null: false

      # Optional contact/profile fields
      t.string :email
      t.string :phone
      t.string :title
      t.string :organization_name
      t.text   :notes

      # Lifecycle fields
      t.datetime :discarded_at
      t.datetime :deactivated_at

      # Audit metadata
      t.references :created_by,     null: true, foreign_key: { to_table: :users }
      t.references :updated_by,     null: true, foreign_key: { to_table: :users }
      t.references :deactivated_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :people, :discarded_at
    add_index :people, "lower(display_name)", name: "index_people_on_lower_display_name"
    add_index :people, "lower(email)",
              name: "index_people_on_lower_email",
              where: "email IS NOT NULL"

    # Enforce exactly one person per linked user
    add_index :people, :user_id,
              unique: true,
              where: "user_id IS NOT NULL",
              name: "index_people_on_user_id_unique_when_present"

  end
end
