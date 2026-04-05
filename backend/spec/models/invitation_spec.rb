require 'rails_helper'

RSpec.describe Invitation, type: :model do
  let(:person) { create(:person, :with_email) }
  let(:admin)  { create(:user, :admin) }

  describe '.generate_for' do
    it 'returns a raw token string' do
      raw = Invitation.generate_for(person, invited_by: admin)
      expect(raw).to be_a(String)
      expect(raw.length).to be >= 32
    end

    it 'creates an invitation record for the person' do
      expect { Invitation.generate_for(person, invited_by: admin) }
        .to change { person.invitations.count }.by(1)
    end

    it 'stores a digest, not the raw token' do
      raw = Invitation.generate_for(person, invited_by: admin)
      invitation = person.invitations.last
      expect(invitation.token_digest).not_to eq(raw)
      expect(invitation.token_digest).to eq(Digest::SHA256.hexdigest(raw))
    end

    it 'snapshots the person email' do
      Invitation.generate_for(person, invited_by: admin)
      expect(person.invitations.last.email_snapshot).to eq(person.email)
    end

    it 'sets expires_at 7 days from now' do
      Invitation.generate_for(person, invited_by: admin)
      expect(person.invitations.last.expires_at).to be_within(5.seconds).of(7.days.from_now)
    end

    it 'revokes any existing active invitation before creating a new one' do
      first_raw  = Invitation.generate_for(person, invited_by: admin)
      first_inv  = person.invitations.last
      second_raw = Invitation.generate_for(person, invited_by: admin)

      expect(first_inv.reload.revoked_at).not_to be_nil
      expect(first_raw).not_to eq(second_raw)
    end
  end

  describe '.find_by_raw_token' do
    it 'returns the matching invitation' do
      raw = Invitation.generate_for(person, invited_by: admin)
      found = Invitation.find_by_raw_token(raw)
      expect(found).to be_a(Invitation)
      expect(found.email_snapshot).to eq(person.email)
    end

    it 'returns nil for an unknown token' do
      expect(Invitation.find_by_raw_token('notavalidtoken')).to be_nil
    end
  end

  describe '#active?' do
    it 'is true for a fresh invitation' do
      raw = Invitation.generate_for(person, invited_by: admin)
      inv = Invitation.find_by_raw_token(raw)
      expect(inv.active?).to be true
    end

    it 'is false after revocation' do
      raw = Invitation.generate_for(person, invited_by: admin)
      inv = Invitation.find_by_raw_token(raw)
      inv.revoke!
      expect(inv.active?).to be false
    end

    it 'is false after acceptance' do
      raw = Invitation.generate_for(person, invited_by: admin)
      inv = Invitation.find_by_raw_token(raw)
      inv.update!(accepted_at: Time.current)
      expect(inv.active?).to be false
    end

    it 'is false when expired' do
      raw = Invitation.generate_for(person, invited_by: admin)
      inv = Invitation.find_by_raw_token(raw)
      inv.update!(expires_at: 1.minute.ago)
      expect(inv.active?).to be false
    end
  end

  describe '#revoke!' do
    it 'sets revoked_at' do
      raw = Invitation.generate_for(person, invited_by: admin)
      inv = Invitation.find_by_raw_token(raw)
      expect { inv.revoke! }.to change { inv.reload.revoked_at }.from(nil)
    end
  end
end
