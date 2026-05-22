# frozen_string_literal: true

class IssuePerson < ApplicationRecord
  belongs_to :issue
  belongs_to :person
  belongs_to :added_by, class_name: 'User', optional: true

  validates :person_id, uniqueness: { scope: :issue_id }
end
