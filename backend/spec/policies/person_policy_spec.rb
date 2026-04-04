require 'rails_helper'

RSpec.describe PersonPolicy do
  subject { described_class }

  let(:person) { create(:person) }

  context 'for admin users' do
    let(:user) { create(:user, :admin) }

    it 'allows index' do
      expect(subject.new(user, Person).index?).to be true
    end

    it 'allows show' do
      expect(subject.new(user, person).show?).to be true
    end

    it 'allows create' do
      expect(subject.new(user, person).create?).to be true
    end

    it 'allows update' do
      expect(subject.new(user, person).update?).to be true
    end

    it 'allows destroy' do
      expect(subject.new(user, person).destroy?).to be true
    end

    describe 'Scope' do
      it 'returns all kept people' do
        create_list(:person, 3)
        create(:person, :discarded)
        scope = PersonPolicy::Scope.new(user, Person).resolve
        expect(scope.count).to eq(3)
      end
    end
  end

  context 'for staff users' do
    let(:user) { create(:user, :with_role, role_name: 'staff') }

    it 'allows index' do
      expect(subject.new(user, Person).index?).to be true
    end

    it 'allows show' do
      expect(subject.new(user, person).show?).to be true
    end

    it 'allows create' do
      expect(subject.new(user, person).create?).to be true
    end

    it 'allows update' do
      expect(subject.new(user, person).update?).to be true
    end

    it 'allows destroy' do
      expect(subject.new(user, person).destroy?).to be true
    end

    describe 'Scope' do
      it 'returns all kept people' do
        create_list(:person, 2)
        scope = PersonPolicy::Scope.new(user, Person).resolve
        expect(scope.count).to eq(2)
      end
    end
  end

  context 'for other authenticated users' do
    let(:user) { create(:user) }

    it 'denies index' do
      expect(subject.new(user, Person).index?).to be false
    end

    it 'denies show' do
      expect(subject.new(user, person).show?).to be false
    end

    it 'denies create' do
      expect(subject.new(user, person).create?).to be false
    end

    it 'denies update' do
      expect(subject.new(user, person).update?).to be false
    end

    it 'denies destroy' do
      expect(subject.new(user, person).destroy?).to be false
    end

    describe 'Scope' do
      it 'returns no people' do
        create_list(:person, 3)
        scope = PersonPolicy::Scope.new(user, Person).resolve
        expect(scope.count).to eq(0)
      end
    end
  end
end
