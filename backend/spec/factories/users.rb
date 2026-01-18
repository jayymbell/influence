FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
  # Password must satisfy custom validator: min length 12, uppercase, lowercase, digit, special char
  password { "Password123!@" }
  password_confirmation { "Password123!@" }
    confirmed_at { Time.current }

    trait :with_role do
      transient do
        roles_count { 1 }
      end

      after(:create) do |user, evaluator|
        create_list(:role, evaluator.roles_count, users: [user])
      end
    end
  end
end
