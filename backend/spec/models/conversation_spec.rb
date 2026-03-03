require 'rails_helper'

RSpec.describe Conversation, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:messages).dependent(:destroy) }
  end

  describe 'validations' do
    it 'allows a blank title' do
      conversation = build(:conversation, title: nil)
      expect(conversation).to be_valid
    end

    it 'rejects titles longer than 255 characters' do
      conversation = build(:conversation, title: 'a' * 256)
      expect(conversation).not_to be_valid
    end
  end

  describe '#generate_title_from_first_message!' do
    it 'sets the title from the first user message' do
      conversation = create(:conversation, title: nil)
      create(:message, conversation: conversation, role: 'user', content: 'Hello, how are you?')

      conversation.generate_title_from_first_message!
      expect(conversation.reload.title).to eq('Hello, how are you?')
    end

    it 'truncates long messages to 100 characters' do
      conversation = create(:conversation, title: nil)
      long_content = 'a' * 200
      create(:message, conversation: conversation, role: 'user', content: long_content)

      conversation.generate_title_from_first_message!
      expect(conversation.reload.title.length).to be <= 100
    end

    it 'does not overwrite an existing title' do
      conversation = create(:conversation, title: 'Existing title')
      create(:message, conversation: conversation, role: 'user', content: 'New message')

      conversation.generate_title_from_first_message!
      expect(conversation.reload.title).to eq('Existing title')
    end
  end
end
