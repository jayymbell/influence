# frozen_string_literal: true

class BillClient < ApplicationRecord
  belongs_to :bill
  belongs_to :client
  belongs_to :shared_by, class_name: 'User', optional: true

  validates :client_id, uniqueness: { scope: :bill_id }
end
