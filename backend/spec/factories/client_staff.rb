FactoryBot.define do
  factory :client_staff do
    association :client
    association :user
  end
end
