class ConversationSerializer
  include JSONAPI::Serializer
  attributes :id, :title, :created_at, :updated_at

  attribute :messages do |conversation|
    conversation.messages.order(:created_at).map do |msg|
      MessageSerializer.new(msg).serializable_hash[:data][:attributes]
    end
  end
end
