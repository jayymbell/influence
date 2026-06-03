# frozen_string_literal: true

class BillAction < ApplicationRecord
  belongs_to :bill

  validates :action_date,  presence: true
  validates :description,  presence: true
  validates :classification, inclusion: { in: BillImportService::ACTION_CLASSIFICATION_PRIORITY.keys + [""] },
                              allow_blank: true

  default_scope { order(action_order: :asc, action_date: :asc) }
end
