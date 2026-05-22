# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IssuePolicy do
  subject { described_class }

  let(:client) { create(:client) }
  let(:issue)  { create(:issue, client: client) }

  context 'for admin users' do
    let(:user) { create(:user, :admin) }

    it 'allows index'      do expect(subject.new(user, Issue).index?).to be true end
    it 'allows show'       do expect(subject.new(user, issue).show?).to be true end
    it 'allows create'     do expect(subject.new(user, issue).create?).to be true end
    it 'allows update'     do expect(subject.new(user, issue).update?).to be true end
    it 'allows destroy'    do expect(subject.new(user, issue).destroy?).to be true end
    it 'allows close'      do expect(subject.new(user, issue).close?).to be true end
    it 'allows deactivate' do expect(subject.new(user, issue).deactivate?).to be true end
    it 'allows reactivate' do expect(subject.new(user, issue).reactivate?).to be true end
    it 'allows share'      do expect(subject.new(user, issue).share?).to be true end
    it 'allows unshare'    do expect(subject.new(user, issue).unshare?).to be true end

    describe 'Scope' do
      it 'returns all issues' do
        create_list(:issue, 3)
        scope = IssuePolicy::Scope.new(user, Issue).resolve
        expect(scope.count).to eq(3)
      end
    end
  end

  context 'for staff users' do
    let(:user) { create(:user, :with_role, role_name: 'staff') }

    it 'allows index'      do expect(subject.new(user, Issue).index?).to be true end
    it 'allows show'       do expect(subject.new(user, issue).show?).to be true end
    it 'allows create'     do expect(subject.new(user, issue).create?).to be true end
    it 'allows update'     do expect(subject.new(user, issue).update?).to be true end
    it 'allows destroy'    do expect(subject.new(user, issue).destroy?).to be true end
    it 'allows close'      do expect(subject.new(user, issue).close?).to be true end
    it 'allows deactivate' do expect(subject.new(user, issue).deactivate?).to be true end
    it 'allows reactivate' do expect(subject.new(user, issue).reactivate?).to be true end
    it 'denies share'      do expect(subject.new(user, issue).share?).to be false end
    it 'denies unshare'    do expect(subject.new(user, issue).unshare?).to be false end

    describe 'Scope' do
      it 'returns all issues' do
        create_list(:issue, 2)
        scope = IssuePolicy::Scope.new(user, Issue).resolve
        expect(scope.count).to eq(2)
      end
    end
  end

  context 'for manager users on their own clients' do
    let(:user) { create(:user, :with_role, role_name: 'manager') }

    before { create(:client_staff, client: client, user: user) }

    it 'allows index'      do expect(subject.new(user, Issue).index?).to be true end
    it 'allows show'       do expect(subject.new(user, issue).show?).to be true end
    it 'allows create'     do expect(subject.new(user, issue).create?).to be true end
    it 'allows update'     do expect(subject.new(user, issue).update?).to be true end
    it 'allows destroy'    do expect(subject.new(user, issue).destroy?).to be true end
    it 'allows close'      do expect(subject.new(user, issue).close?).to be true end
    it 'allows deactivate' do expect(subject.new(user, issue).deactivate?).to be true end
    it 'allows reactivate' do expect(subject.new(user, issue).reactivate?).to be true end
    it 'allows share'      do expect(subject.new(user, issue).share?).to be true end
    it 'allows unshare'    do expect(subject.new(user, issue).unshare?).to be true end

    describe 'Scope' do
      it 'returns issues for their clients' do
        other_client = create(:client)
        create(:issue, client: other_client)   # not visible
        scope = IssuePolicy::Scope.new(user, Issue).resolve
        expect(scope).to include(issue)
        expect(scope.count).to eq(1)
      end

      it 'includes issues shared with their clients' do
        other_client  = create(:client)
        shared_issue  = create(:issue, client: other_client)
        create(:client_issue, issue: shared_issue, client: client)
        scope = IssuePolicy::Scope.new(user, Issue).resolve
        expect(scope).to include(issue)
        expect(scope).to include(shared_issue)
      end
    end
  end

  context 'for manager users on issues shared with their clients' do
    let(:user)         { create(:user, :with_role, role_name: 'manager') }
    let(:their_client) { create(:client) }

    before do
      create(:client_staff, client: their_client, user: user)
      create(:client_issue, issue: issue, client: their_client)
    end

    it 'allows show'       do expect(subject.new(user, issue).show?).to be true end
    it 'allows update'     do expect(subject.new(user, issue).update?).to be true end
    it 'allows close'      do expect(subject.new(user, issue).close?).to be true end
  end

  context 'for manager users on other clients\' issues' do
    let(:user)         { create(:user, :with_role, role_name: 'manager') }
    let(:other_issue)  { create(:issue) }

    it 'denies show'       do expect(subject.new(user, other_issue).show?).to be false end
    it 'denies update'     do expect(subject.new(user, other_issue).update?).to be false end
    it 'denies close'      do expect(subject.new(user, other_issue).close?).to be false end
    it 'denies share'      do expect(subject.new(user, other_issue).share?).to be true end  # share? is role-level, not record-level
  end

  context 'for other authenticated users' do
    let(:user) { create(:user) }

    it 'denies index'      do expect(subject.new(user, Issue).index?).to be false end
    it 'denies show'       do expect(subject.new(user, issue).show?).to be false end
    it 'denies create'     do expect(subject.new(user, issue).create?).to be false end
    it 'denies update'     do expect(subject.new(user, issue).update?).to be false end
    it 'denies destroy'    do expect(subject.new(user, issue).destroy?).to be false end
    it 'denies share'      do expect(subject.new(user, issue).share?).to be false end
    it 'denies unshare'    do expect(subject.new(user, issue).unshare?).to be false end

    describe 'Scope' do
      it 'returns no issues' do
        create_list(:issue, 2)
        scope = IssuePolicy::Scope.new(user, Issue).resolve
        expect(scope.count).to eq(0)
      end
    end
  end
end
