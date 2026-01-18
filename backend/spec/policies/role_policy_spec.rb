require 'rails_helper'

RSpec.describe RolePolicy do
  subject { described_class }

  let(:role) { create(:role) }

  context 'for admin users' do
    let(:user) { create(:user, :admin) }

    it 'allows index' do
      expect(subject.new(user, Role).index?).to be true
    end

    it 'allows create' do
      expect(subject.new(user, role).create?).to be true
    end
  end

  context 'for non-admin users' do
    let(:user) { create(:user) }

    it 'denies index' do
      expect(subject.new(user, Role).index?).to be false
    end
  end
end
