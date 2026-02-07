require 'rails_helper'

RSpec.describe RolePolicy do
  subject { described_class }

  let(:role) { create(:role) }

  context 'for admin users' do
    let(:user) { create(:user, :admin) }

    it 'allows index' do
      expect(subject.new(user, Role).index?).to be true
    end

    it 'allows show' do
      expect(subject.new(user, role).show?).to be true
    end

    it 'allows create' do
      expect(subject.new(user, role).create?).to be true
    end

    it 'allows update' do
      expect(subject.new(user, role).update?).to be true
    end

    it 'allows destroy for non-admin roles' do
      regular_role = create(:role, name: 'regular_role')
      expect(subject.new(user, regular_role).destroy?).to be true
    end

    it 'prevents destroy for admin role' do
      admin_role = Role.find_or_create_by!(name: 'admin') { |r| r.description = 'Administrator' }
      expect(subject.new(user, admin_role).destroy?).to be false
    end

    describe 'Scope' do
      it 'returns all roles' do
        create_list(:role, 3)
        scope = RolePolicy::Scope.new(user, Role).resolve
        expect(scope.count).to be >= 3
      end
    end
  end

  context 'for non-admin users' do
    let(:user) { create(:user) }

    it 'denies index' do
      expect(subject.new(user, Role).index?).to be false
    end

    it 'denies show' do
      expect(subject.new(user, role).show?).to be false
    end

    it 'denies create' do
      expect(subject.new(user, role).create?).to be false
    end

    it 'denies update' do
      expect(subject.new(user, role).update?).to be false
    end

    it 'denies destroy' do
      expect(subject.new(user, role).destroy?).to be false
    end

    describe 'Scope' do
      it 'returns no roles' do
        create_list(:role, 3)
        scope = RolePolicy::Scope.new(user, Role).resolve
        expect(scope.count).to eq(0)
      end
    end
  end
end
