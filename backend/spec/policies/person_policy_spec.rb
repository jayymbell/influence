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

    it 'allows reactivate' do
      expect(subject.new(user, person).reactivate?).to be true
    end

    describe 'Scope' do
      it 'returns all people including discarded' do
        create_list(:person, 3)
        create(:person, :discarded)
        scope = PersonPolicy::Scope.new(user, Person).resolve
        expect(scope.count).to eq(4)
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

    it 'allows reactivate' do
      expect(subject.new(user, person).reactivate?).to be true
    end

    describe 'Scope' do
      it 'returns all people including discarded' do
        create_list(:person, 2)
        create(:person, :discarded)
        scope = PersonPolicy::Scope.new(user, Person).resolve
        expect(scope.count).to eq(3)
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

    it 'denies create for an unowned person record' do
      expect(subject.new(user, person).create?).to be false
    end

    it 'denies update' do
      expect(subject.new(user, person).update?).to be false
    end

    it 'denies destroy' do
      expect(subject.new(user, person).destroy?).to be false
    end

    it 'denies reactivate' do
      expect(subject.new(user, person).reactivate?).to be false
    end

    describe 'Scope' do
      it 'returns no people' do
        create_list(:person, 3)
        scope = PersonPolicy::Scope.new(user, Person).resolve
        expect(scope.count).to eq(0)
      end
    end
  end

  context 'for a user creating their own person' do
    let(:user) { create(:user) }
    let(:own_person) { build(:person, user: user) }

    it 'allows create when person is linked to themselves' do
      expect(subject.new(user, own_person).create?).to be true
    end
  end

  context 'for a user accessing their own linked person' do
    let(:user) { create(:user) }
    let(:own_person) { create(:person, user: user) }

    it 'allows show' do
      expect(subject.new(user, own_person).show?).to be true
    end

    it 'allows update' do
      expect(subject.new(user, own_person).update?).to be true
    end

    it 'denies destroy' do
      expect(subject.new(user, own_person).destroy?).to be false
    end
  end
end
