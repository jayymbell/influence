class RefreshToken < ApplicationRecord
  belongs_to :user

  before_create :set_expires_at
  before_create :generate_token

  scope :active, -> { where('expires_at > ?', Time.current).where(revoked_at: nil) }
  
  def revoke!
    update!(revoked_at: Time.current)
  end

  def expired?
    expires_at <= Time.current
  end

  def active?
    !expired? && !revoked_at
  end

  private

  def set_expires_at
    self.expires_at = 30.days.from_now
  end

  def generate_token
    self.token = loop do
      random_token = SecureRandom.urlsafe_base64(48)
      break random_token unless RefreshToken.exists?(token: random_token)
    end
  end
end