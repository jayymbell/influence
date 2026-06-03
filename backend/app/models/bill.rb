# frozen_string_literal: true

class Bill < ApplicationRecord
  enum :status, {
    introduced:           0,
    in_committee:         1,
    passed_committee:     2,
    floor_vote:           3,
    passed_chamber:       4,
    passed_both_chambers: 5,
    signed:               6,
    vetoed:               7,
    failed:               8,
    carried_over:         9
  }, default: :introduced

  enum :chamber, { house: 0, senate: 1 }

  belongs_to :companion_bill, class_name: 'Bill', optional: true
  belongs_to :created_by,     class_name: 'User', optional: true
  belongs_to :updated_by,     class_name: 'User', optional: true

  has_many :bill_issues,  dependent: :destroy
  has_many :issues,       through: :bill_issues

  has_many :bill_clients, dependent: :destroy
  has_many :clients,      through: :bill_clients

  has_many :bill_people,   dependent: :destroy
  has_many :people,        through: :bill_people

  has_many :bill_actions,  dependent: :destroy

  validates :title, presence: true, length: { minimum: 2 }
  validates :status, presence: true
  validate  :companion_bill_not_self

  private

  def companion_bill_not_self
    errors.add(:companion_bill_id, 'cannot reference itself') if companion_bill_id == id && id.present?
  end
end
