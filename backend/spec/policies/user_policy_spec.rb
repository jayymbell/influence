require 'rails_helper'

RSpec.describe UserPolicy do
  subject { described_class }

  let(:user_record) { create(:user) }

  context 'for admin users' do
    let(:user) { create(:user) }

    before do
      admin = Role.find_or_create_by!(name: 'admin') { |r| r.description = 'Administrator' }
      user.roles << admin
    end

    it 'allows index' do
      expect(subject.new(user, User).index?).to be true
    end

    it 'allows destroy' do
      expect(subject.new(user, user_record).destroy?).to be true
    end
  end

  context 'for non-admin users' do
    let(:user) { create(:user) }

    it 'denies index' do
      expect(subject.new(user, User).index?).to be false
    end
  end
end
