class AddUniqueIndexToBillsExternalId < ActiveRecord::Migration[8.0]
  def change
    remove_index :bills, :external_id, if_exists: true
    add_index :bills, :external_id, unique: true, where: "external_id IS NOT NULL",
              name: "index_bills_on_external_id_unique"
  end
end
