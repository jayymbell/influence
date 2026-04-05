class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :person,     null: false, foreign_key: true
      t.references :created_by, null: true,  foreign_key: { to_table: :users }

      t.string   :token_digest,    null: false
      t.string   :email_snapshot,  null: false
      t.datetime :expires_at,      null: false
      t.datetime :accepted_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :invitations, :token_digest, unique: true
  end
end
