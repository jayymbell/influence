# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BillPolicy do
  subject { described_class }

  let(:client) { create(:client) }
  let(:bill)   { create(:bill) }

  context 'for admin users' do
    let(:user) { create(:user, :admin) }

    it 'allows index'   do expect(subject.new(user, Bill).index?).to be true end
    it 'allows show'    do expect(subject.new(user, bill).show?).to be true end
    it 'allows create'  do expect(subject.new(user, bill).create?).to be true end
    it 'allows update'  do expect(subject.new(user, bill).update?).to be true end
    it 'allows destroy' do expect(subject.new(user, bill).destroy?).to be true end

    describe 'Scope' do
      it 'returns all bills' do
        create_list(:bill, 3)
        scope = BillPolicy::Scope.new(user, Bill).resolve
        expect(scope.count).to eq(3)
      end
    end
  end

  context 'for staff users' do
    let(:user) { create(:user, :with_role, role_name: 'staff') }

    it 'allows index'   do expect(subject.new(user, Bill).index?).to be true end
    it 'allows show'    do expect(subject.new(user, bill).show?).to be true end
    it 'allows create'  do expect(subject.new(user, bill).create?).to be true end
    it 'allows update'  do expect(subject.new(user, bill).update?).to be true end
    it 'allows destroy' do expect(subject.new(user, bill).destroy?).to be true end

    describe 'Scope' do
      it 'returns all bills' do
        create_list(:bill, 2)
        scope = BillPolicy::Scope.new(user, Bill).resolve
        expect(scope.count).to eq(2)
      end
    end
  end

  context 'for manager users on their own clients' do
    let(:user) { create(:user, :with_role, role_name: 'manager') }

    before do
      create(:client_staff, client: client, user: user)
      create(:bill_client, bill: bill, client: client)
    end

    it 'allows index'   do expect(subject.new(user, Bill).index?).to be true end
    it 'allows show'    do expect(subject.new(user, bill).show?).to be true end
    it 'allows create'  do expect(subject.new(user, bill).create?).to be true end
    it 'allows update'  do expect(subject.new(user, bill).update?).to be true end
    it 'allows destroy' do expect(subject.new(user, bill).destroy?).to be true end

    describe 'Scope' do
      it 'returns only bills linked to their clients' do
        other_client = create(:client)
        other_bill   = create(:bill)
        create(:bill_client, bill: other_bill, client: other_client)

        scope = BillPolicy::Scope.new(user, Bill).resolve
        expect(scope).to include(bill)
        expect(scope).not_to include(other_bill)
      end
    end
  end

  context 'for manager users on other clients\' bills' do
    let(:user)       { create(:user, :with_role, role_name: 'manager') }
    let(:other_bill) { create(:bill) }

    it 'denies show'    do expect(subject.new(user, other_bill).show?).to be false end
    it 'denies update'  do expect(subject.new(user, other_bill).update?).to be false end
    it 'denies destroy' do expect(subject.new(user, other_bill).destroy?).to be false end
  end

  context 'for unauthorized users' do
    let(:user) { create(:user) }

    it 'denies index'  do expect(subject.new(user, Bill).index?).to be false end
    it 'denies show'   do expect(subject.new(user, bill).show?).to be false end
    it 'denies create' do expect(subject.new(user, bill).create?).to be false end
  end
end
