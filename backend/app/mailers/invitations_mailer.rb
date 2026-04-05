class InvitationsMailer < ApplicationMailer
  def invite(invitation, raw_token)
    @invitation  = invitation
    @raw_token   = raw_token
    @accept_url  = "#{frontend_url}/invite/accept?token=#{raw_token}"
    @person_name = invitation.person.display_name
    @expires_at  = invitation.expires_at.strftime('%B %-d, %Y')

    mail(
      to:      invitation.email_snapshot,
      subject: "You've been invited to join"
    )
  end

  private

  def frontend_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:5173')
  end
end
