class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  include Discard::Model
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :jwt_authenticatable, jwt_revocation_strategy: self

  # Custom password validation
  validates :password, password: true, if: :password_required?
  has_many :events, class_name: 'Ahoy::Event', dependent: :destroy
  has_many :visits, class_name: 'Ahoy::Visit', dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :refresh_tokens, dependent: :destroy
  has_many :conversations, dependent: :destroy

  def active_for_authentication?
    super && !discarded?
  end

  def inactive_message
    discarded? ? :discarded_account : super
  end

  def admin?
    roles.exists?(name: 'admin')
  end
end
