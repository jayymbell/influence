class AddPinnedToBillNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :bill_notes, :pinned, :boolean, default: false, null: false
  end
end
