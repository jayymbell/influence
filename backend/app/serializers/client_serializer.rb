# frozen_string_literal: true

class ClientSerializer
  include JSONAPI::Serializer

  attributes :id,
             :legal_name,
             :display_name,
             :discarded_at,
             :deactivated_at,
             :created_at,
             :updated_at

  attribute :status do |client|
    client.discarded? ? 'inactive' : 'active'
  end

  attribute :created_by do |client|
    client.created_by ? { id: client.created_by.id, email: client.created_by.email } : nil
  end

  attribute :updated_by do |client|
    client.updated_by ? { id: client.updated_by.id, email: client.updated_by.email } : nil
  end

  attribute :deactivated_by do |client|
    client.deactivated_by ? { id: client.deactivated_by.id, email: client.deactivated_by.email } : nil
  end
end
