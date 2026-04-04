class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :created_at, :discarded_at, :system_user

  attribute :person_id do |user|
    user.person&.id
  end

  attribute :roles do |user|
    user.roles.select(:id, :name, :description)
  end
end
