# frozen_string_literal: true

class Client < ApplicationRecord
  include Discard::Model

  has_many :people

  belongs_to :created_by,     class_name: 'User', optional: true
  belongs_to :updated_by,     class_name: 'User', optional: true
  belongs_to :deactivated_by, class_name: 'User', optional: true

  validates :legal_name,   presence: true, length: { minimum: 2 }, uniqueness: { case_sensitive: false }
  validates :display_name, presence: true

  def status
    discarded? ? 'inactive' : 'active'
  end
end
