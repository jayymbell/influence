class Person < ApplicationRecord
  include Discard::Model

  belongs_to :user, optional: true

  # People who are contacts: no linked user, or linked user has the 'client' role
  scope :contacts, -> {
    client_user_ids = User.joins(:roles).where(roles: { name: 'client' })
    where(user: nil).or(where(user: client_user_ids))
  }
  has_many :invitations, dependent: :destroy
  has_one :active_invitation, -> { active }, class_name: 'Invitation'

  belongs_to :created_by,     class_name: 'User', optional: true
  belongs_to :updated_by,     class_name: 'User', optional: true
  belongs_to :deactivated_by, class_name: 'User', optional: true

  validates :first_name,   presence: true
  validates :last_name,    presence: true
  validates :display_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :user_id, uniqueness: { allow_nil: true }

end
