class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :created_at, :discarded_at, :system_user

  attribute :person_id do |user|
    user.person&.id
  end

  attribute :person_display_name do |user|
    user.person&.display_name
  end

  attribute :roles do |user|
    user.roles.select(:id, :name, :description)
  end
end
