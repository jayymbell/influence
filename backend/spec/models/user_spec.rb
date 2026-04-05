require 'rails_helper'

RSpec.describe User, type: :model do
  it 'responds to admin? based on assigned roles' do
    user = create(:user)
    expect(user.admin?).to be(false)

    admin_role = Role.find_or_create_by!(name: 'admin') do |r|
      r.description = 'Administrator'
    end
    user.roles << admin_role unless user.roles.exists?(name: 'admin')
    expect(user.admin?).to be(true)
  end

  it 'responds to staff? based on assigned roles' do
    user = create(:user)
    expect(user.staff?).to be(false)

    staff_role = Role.find_or_create_by!(name: 'staff') do |r|
      r.description = 'Staff'
    end
    user.roles << staff_role
    expect(user.staff?).to be(true)
  end

  it 'is discardable (soft delete) and inactive_for_authentication when discarded' do
    user = create(:user)
    expect(user.discarded?).to be(false)
    user.discard
    expect(user.discarded?).to be(true)
    expect(user.active_for_authentication?).to be_falsey
  end
end
