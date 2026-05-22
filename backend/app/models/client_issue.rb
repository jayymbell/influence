# frozen_string_literal: true

class ClientIssue < ApplicationRecord
  belongs_to :client
  belongs_to :issue
  belongs_to :shared_by, class_name: 'User', optional: true

  validates :client_id, uniqueness: { scope: :issue_id }
end
