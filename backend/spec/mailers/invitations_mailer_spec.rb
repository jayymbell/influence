require 'rails_helper'

RSpec.describe InvitationsMailer, type: :mailer do
  let(:person) { create(:person, :with_email) }
  let(:admin)  { create(:user, :admin) }

  describe '#invite' do
    let(:raw_token)  { Invitation.generate_for(person, invited_by: admin) }
    # Evaluate raw_token first so the invitation record exists before we query it
    let(:invitation) { raw_token; person.reload.active_invitation }
    let(:mail)       { InvitationsMailer.invite(invitation, raw_token) }

    it 'sends to the invitation email snapshot' do
      expect(mail.to).to eq([invitation.email_snapshot])
    end

    it 'has an invitation subject' do
      expect(mail.subject).to match(/invited/i)
    end

    it 'includes the raw token in the accept link' do
      expect(mail.text_part.decoded).to include(raw_token)
    end

    it 'includes the accept path in the link' do
      expect(mail.text_part.decoded).to include('/invite/accept')
    end
  end
end
