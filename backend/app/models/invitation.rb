class Invitation < ApplicationRecord
  belongs_to :person
  belongs_to :created_by, class_name: 'User', optional: true

  EXPIRY_DAYS = 7

  scope :active, -> {
    where(accepted_at: nil, revoked_at: nil).where('expires_at > ?', Time.current)
  }

  def active?
    accepted_at.nil? && revoked_at.nil? && expires_at > Time.current
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def self.generate_for(person, invited_by: nil)
    raw_token = SecureRandom.urlsafe_base64(32)
    digest    = Digest::SHA256.hexdigest(raw_token)

    person.invitations.active.find_each(&:revoke!)

    person.invitations.create!(
      token_digest:   digest,
      email_snapshot: person.email,
      expires_at:     EXPIRY_DAYS.days.from_now,
      created_by:     invited_by
    )

    raw_token
  end

  def self.find_by_raw_token(raw_token)
    digest = Digest::SHA256.hexdigest(raw_token.to_s)
    find_by(token_digest: digest)
  end
end
