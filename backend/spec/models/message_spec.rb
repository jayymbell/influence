require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:conversation) }
  end

  describe 'validations' do
    it 'requires a role' do
      message = build(:message, role: nil)
      expect(message).not_to be_valid
    end

    it 'requires content' do
      message = build(:message, content: nil)
      expect(message).not_to be_valid
    end

    it 'only allows user and assistant roles' do
      expect(build(:message, role: 'user')).to be_valid
      expect(build(:message, role: 'assistant')).to be_valid
      expect(build(:message, role: 'system')).not_to be_valid
    end
  end
end
