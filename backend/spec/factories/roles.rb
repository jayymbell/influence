FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "role_#{n}" }
    description { "Role description" }

    trait :admin do
      name { 'admin' }
    end
  end
end
