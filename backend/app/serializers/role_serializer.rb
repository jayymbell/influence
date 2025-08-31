class RoleSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :description

  attribute :users do |role|
    role.users.select(:id, :email, :discarded_at)
  end 
end
