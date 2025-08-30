class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email

  attribute :roles do |user|
    user.roles.pluck(:name)
  end
end
