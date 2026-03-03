class MessageSerializer
  include JSONAPI::Serializer
  attributes :id, :role, :content, :created_at
end
