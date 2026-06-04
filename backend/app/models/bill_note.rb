# frozen_string_literal: true

class BillNote < ApplicationRecord
  belongs_to :bill
  belongs_to :user

  validates :content, presence: true

  scope :visible_to, ->(user) {
    where(shared: true).or(where(user_id: user.id))
  }

  validate :pinned_requires_shared

  private

  def pinned_requires_shared
    errors.add(:pinned, 'can only be set on shared notes') if pinned? && !shared?
  end
end
