# frozen_string_literal: true

class ClientStaff < ApplicationRecord
  self.table_name = 'client_staff'

  belongs_to :client
  belongs_to :user

  validates :user_id, uniqueness: { scope: :client_id }
end
