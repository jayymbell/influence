class AddInviteAsToInvitations < ActiveRecord::Migration[8.0]
  def change
    add_column :invitations, :invite_as, :string
  end
end
