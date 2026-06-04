class AddSharedToBillNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :bill_notes, :shared, :boolean, default: false, null: false
  end
end
