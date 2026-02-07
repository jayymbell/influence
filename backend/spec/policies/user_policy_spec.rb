require 'rails_helper'

RSpec.describe UserPolicy do
  subject { described_class }

  let(:user_record) { create(:user) }

  context 'for admin users' do
    let(:user) { create(:user, :admin) }

    it 'allows index' do
      expect(subject.new(user, User).index?).to be true
    end

    it 'allows show' do
      expect(subject.new(user, user_record).show?).to be true
    end

    it 'allows create' do
      expect(subject.new(user, User).create?).to be true
    end

    it 'allows update' do
      expect(subject.new(user, user_record).update?).to be true
    end

    it 'allows destroy' do
      expect(subject.new(user, user_record).destroy?).to be true
    end

    describe 'Scope' do
      it 'returns all users' do
        initial_count = User.count
        create_list(:user, 3)
        scope = UserPolicy::Scope.new(user, User).resolve
        expect(scope.count).to eq(initial_count + 4) # initial + 3 created + 1 admin user
      end
    end
  end

  context 'for non-admin users' do
    let(:user) { create(:user) }

    it 'denies index' do
      expect(subject.new(user, User).index?).to be false
    end

    it 'denies show' do
      expect(subject.new(user, user_record).show?).to be false
    end

    it 'denies create' do
      expect(subject.new(user, User).create?).to be false
    end

    it 'denies update' do
      expect(subject.new(user, user_record).update?).to be false
    end

    it 'denies destroy' do
      expect(subject.new(user, user_record).destroy?).to be false
    end

    describe 'Scope' do
      it 'returns no users' do
        create_list(:user, 3)
        scope = UserPolicy::Scope.new(user, User).resolve
        expect(scope.count).to eq(0)
      end
    end
  end
end
