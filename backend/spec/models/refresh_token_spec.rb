# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshToken, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      user = create(:user)
      token = create(:refresh_token, user: user)
      expect(token.user).to eq(user)
    end
  end

  describe 'callbacks' do
    describe 'before_create :set_expires_at' do
      it 'sets expires_at to 30 days from now when not provided' do
        user = create(:user)
        token = RefreshToken.new(user: user)
        expect(token.expires_at).to be_nil

        token.save!
        expect(token.expires_at).to be_within(1.second).of(30.days.from_now)
      end
    end

    describe 'before_create :generate_token' do
      it 'generates a unique token' do
        token = create(:refresh_token)
        expect(token.token).to be_present
        expect(token.token.length).to be > 0
      end

      it 'generates different tokens for different records' do
        token1 = create(:refresh_token)
        token2 = create(:refresh_token)
        expect(token1.token).not_to eq(token2.token)
      end

      it 'generates a URL-safe base64 token' do
        token = create(:refresh_token)
        # URL-safe base64 should not contain +, /, or = padding (or minimal =)
        expect(token.token).not_to match(/[+\/]/)
      end
    end
  end

  describe '#expired?' do
    it 'returns false when expires_at is in the future' do
      token = create(:refresh_token, expires_at: 1.day.from_now)
      expect(token.expired?).to be false
    end

    it 'returns true when expires_at is in the past' do
      past_time = 1.day.ago
      token = create(:refresh_token)
      token.update_column(:expires_at, past_time)
      token.reload
      expect(token.expired?).to be true
    end

    it 'returns true when expires_at is in the past (within a second)' do
      past_time = 2.seconds.ago
      token = create(:refresh_token)
      token.update_column(:expires_at, past_time)
      token.reload
      expect(token.expired?).to be true
    end
  end

  describe '#active?' do
    it 'returns true when not expired and not revoked' do
      token = create(:refresh_token)
      token.update_column(:expires_at, 1.day.from_now)
      token.reload
      expect(token.active?).to be true
    end

    it 'returns false when expired' do
      token = create(:refresh_token)
      token.update_column(:expires_at, 1.day.ago)
      token.reload
      expect(token.active?).to be false
    end

    it 'returns false when revoked' do
      token = create(:refresh_token, expires_at: 1.day.from_now, revoked_at: 1.hour.ago)
      expect(token.active?).to be false
    end

    it 'returns false when both expired and revoked' do
      token = create(:refresh_token, expires_at: 1.day.ago, revoked_at: 1.hour.ago)
      expect(token.active?).to be false
    end
  end

  describe '#revoke!' do
    it 'sets revoked_at to current time' do
      token = create(:refresh_token, revoked_at: nil)
      expect(token.revoked_at).to be_nil

      token.revoke!
      expect(token.revoked_at).to be_within(1.second).of(Time.current)
    end

    it 'updates the database record' do
      token = create(:refresh_token, revoked_at: nil)
      token.revoke!

      token.reload
      expect(token.revoked_at).to be_present
    end
  end

  describe 'scope :active' do
    let(:user) { create(:user) }

    it 'returns only non-expired, non-revoked tokens' do
      active_token1 = create(:refresh_token, user: user)
      active_token1.update_column(:expires_at, 1.day.from_now)
      
      active_token2 = create(:refresh_token, user: user)
      active_token2.update_column(:expires_at, 2.days.from_now)
      
      expired_token = create(:refresh_token, user: user)
      expired_token.update_column(:expires_at, 1.day.ago)
      
      revoked_token = create(:refresh_token, user: user)
      revoked_token.update_column(:expires_at, 1.day.from_now)
      revoked_token.update_column(:revoked_at, 1.hour.ago)

      active_tokens = RefreshToken.active

      expect(active_tokens).to include(active_token1.reload, active_token2.reload)
      expect(active_tokens.map(&:id)).not_to include(expired_token.id, revoked_token.id)
    end

    it 'excludes tokens that expire in the past' do
      expired_token = create(:refresh_token, user: user)
      expired_token.update_column(:expires_at, 1.second.ago)

      expect(RefreshToken.active.map(&:id)).not_to include(expired_token.id)
    end
  end
end
