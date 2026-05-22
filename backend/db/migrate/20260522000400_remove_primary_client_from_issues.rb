# frozen_string_literal: true

class RemovePrimaryClientFromIssues < ActiveRecord::Migration[8.0]
  def up
    # Migrate existing data: ensure every issue has a client_issues row before dropping client_id
    execute <<~SQL
      INSERT INTO client_issues (client_id, issue_id, created_at, updated_at)
      SELECT i.client_id, i.id, NOW(), NOW()
      FROM issues i
      WHERE i.client_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM client_issues ci
          WHERE ci.issue_id = i.id AND ci.client_id = i.client_id
        )
    SQL

    remove_foreign_key :issues, column: :client_id
    remove_column :issues, :client_id

    remove_column :client_issues, :is_primary
  end

  def down
    add_column :issues, :client_id, :bigint
    add_foreign_key :issues, :clients, column: :client_id

    add_column :client_issues, :is_primary, :boolean, default: false, null: false
  end
end
