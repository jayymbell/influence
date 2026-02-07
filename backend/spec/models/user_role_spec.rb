# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserRole, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      user = create(:user)
      role = create(:role)
      user_role = create(:user_role, user: user, role: role)
      expect(user_role.user).to eq(user)
    end

    it 'belongs to role' do
      user = create(:user)
      role = create(:role)
      user_role = create(:user_role, user: user, role: role)
      expect(user_role.role).to eq(role)
    end
  end

  describe 'factory' do
    it 'creates a valid user_role' do
      user_role = create(:user_role)
      expect(user_role).to be_valid
      expect(user_role.user).to be_present
      expect(user_role.role).to be_present
    end
  end
end
