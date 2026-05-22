# frozen_string_literal: true

class BillPerson < ApplicationRecord
  belongs_to :bill
  belongs_to :person
  belongs_to :added_by, class_name: 'User', optional: true

  validates :person_id, uniqueness: { scope: :bill_id }
end
