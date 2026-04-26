# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientPolicy do
  subject { described_class }

  let(:client) { create(:client) }

  context 'for admin users' do
    let(:user) { create(:user, :admin) }

    it 'allows index'      do expect(subject.new(user, Client).index?).to be true end
    it 'allows show'       do expect(subject.new(user, client).show?).to be true end
    it 'allows create'     do expect(subject.new(user, client).create?).to be true end
    it 'allows update'     do expect(subject.new(user, client).update?).to be true end
    it 'allows destroy'    do expect(subject.new(user, client).destroy?).to be true end
    it 'allows reactivate' do expect(subject.new(user, client).reactivate?).to be true end

    describe 'Scope' do
      it 'returns all clients' do
        create_list(:client, 2)
        create(:client, :discarded)
        scope = ClientPolicy::Scope.new(user, Client).resolve
        expect(scope.count).to eq(3)
      end
    end
  end

  context 'for staff users' do
    let(:user) { create(:user, :with_role, role_name: 'staff') }

    it 'allows index'      do expect(subject.new(user, Client).index?).to be true end
    it 'allows show'       do expect(subject.new(user, client).show?).to be true end
    it 'allows create'     do expect(subject.new(user, client).create?).to be true end
    it 'allows update'     do expect(subject.new(user, client).update?).to be true end
    it 'allows destroy'    do expect(subject.new(user, client).destroy?).to be true end
    it 'allows reactivate' do expect(subject.new(user, client).reactivate?).to be true end

    describe 'Scope' do
      it 'returns all clients' do
        create_list(:client, 2)
        scope = ClientPolicy::Scope.new(user, Client).resolve
        expect(scope.count).to eq(2)
      end
    end
  end

  context 'for other authenticated users' do
    let(:user) { create(:user) }

    it 'denies index'      do expect(subject.new(user, Client).index?).to be false end
    it 'denies show'       do expect(subject.new(user, client).show?).to be false end
    it 'denies create'     do expect(subject.new(user, client).create?).to be false end
    it 'denies update'     do expect(subject.new(user, client).update?).to be false end
    it 'denies destroy'    do expect(subject.new(user, client).destroy?).to be false end
    it 'denies reactivate' do expect(subject.new(user, client).reactivate?).to be false end

    describe 'Scope' do
      it 'returns no clients' do
        create_list(:client, 2)
        scope = ClientPolicy::Scope.new(user, Client).resolve
        expect(scope.count).to eq(0)
      end
    end
  end
end
