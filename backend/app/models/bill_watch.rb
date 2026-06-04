# frozen_string_literal: true

class BillWatch < ApplicationRecord
  belongs_to :user
  belongs_to :bill

  validates :user_id, uniqueness: { scope: :bill_id, message: "is already watching this bill" }
end
