# frozen_string_literal: true

class BillIssue < ApplicationRecord
  belongs_to :bill
  belongs_to :issue
  belongs_to :added_by, class_name: 'User', optional: true

  validates :issue_id, uniqueness: { scope: :bill_id }
end
