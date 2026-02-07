require 'rails_helper'

RSpec.describe ApplicationPolicy do
  let(:user) { double('User') }
  let(:record) { double('Record') }

  subject { described_class.new(user, record) }

  describe 'default permissions' do
    it 'denies index, show, create, update, and destroy by default' do
      expect(subject.index?).to be false
      expect(subject.show?).to be false
      expect(subject.create?).to be false
      expect(subject.update?).to be false
      expect(subject.destroy?).to be false
    end

    it 'delegates new? to create? and edit? to update?' do
      policy_class = Class.new(ApplicationPolicy) do
        def create?; true; end
        def update?; true; end
      end

      policy = policy_class.new(user, record)
      expect(policy.new?).to be true
      expect(policy.edit?).to be true
    end
  end

  describe 'Scope' do
    it 'raises NoMethodError if #resolve is not implemented' do
      dummy_scope = Class.new
      scope = ApplicationPolicy::Scope.new(user, dummy_scope)
      expect { scope.resolve }.to raise_error(NoMethodError, /You must define #resolve/)
    end
  end
end
