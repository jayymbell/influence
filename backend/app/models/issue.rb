# frozen_string_literal: true

class Issue < ApplicationRecord
  enum :status, { active: 0, inactive: 1, closed: 2 }, default: :active

  belongs_to :created_by,  class_name: 'User', optional: true
  belongs_to :updated_by,  class_name: 'User', optional: true
  belongs_to :closed_by,   class_name: 'User', optional: true

  has_many :client_issues,  dependent: :destroy
  has_many :clients,         through: :client_issues

  has_many :issue_people,   dependent: :destroy
  has_many :people,         through: :issue_people

  validates :title, presence: true, length: { minimum: 2 }
  validates :status, presence: true
end
