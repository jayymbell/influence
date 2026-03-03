require 'rails_helper'

RSpec.describe ConversationPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:conversation) { create(:conversation, user: user) }
  let(:other_conversation) { create(:conversation, user: other_user) }

  describe '#index?' do
    it 'allows any authenticated user' do
      policy = described_class.new(user, Conversation)
      expect(policy.index?).to be(true)
    end
  end

  describe '#create?' do
    it 'allows any authenticated user' do
      policy = described_class.new(user, Conversation)
      expect(policy.create?).to be(true)
    end
  end

  describe '#show?' do
    it 'allows the owner' do
      policy = described_class.new(user, conversation)
      expect(policy.show?).to be(true)
    end

    it 'denies another user' do
      policy = described_class.new(user, other_conversation)
      expect(policy.show?).to be(false)
    end
  end

  describe '#update?' do
    it 'allows the owner' do
      policy = described_class.new(user, conversation)
      expect(policy.update?).to be(true)
    end

    it 'denies another user' do
      policy = described_class.new(user, other_conversation)
      expect(policy.update?).to be(false)
    end
  end

  describe '#destroy?' do
    it 'allows the owner' do
      policy = described_class.new(user, conversation)
      expect(policy.destroy?).to be(true)
    end

    it 'denies another user' do
      policy = described_class.new(user, other_conversation)
      expect(policy.destroy?).to be(false)
    end
  end

  describe '#send_message?' do
    it 'allows the owner' do
      policy = described_class.new(user, conversation)
      expect(policy.send_message?).to be(true)
    end

    it 'denies another user' do
      policy = described_class.new(user, other_conversation)
      expect(policy.send_message?).to be(false)
    end
  end

  describe 'Scope' do
    it 'returns only the user\'s conversations' do
      own = create(:conversation, user: user)
      _other = create(:conversation, user: other_user)

      scope = Pundit.policy_scope(user, Conversation)
      expect(scope).to include(own)
      expect(scope).not_to include(_other)
    end
  end
end
