class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :jwt_authenticatable, jwt_revocation_strategy: self
  has_many :events, class_name: 'Ahoy::Event', dependent: :destroy
  has_many :visits, class_name: 'Ahoy::Visit', dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
end
