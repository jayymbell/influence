FactoryBot.define do
  factory :person do
    sequence(:first_name) { |n| "First#{n}" }
    sequence(:last_name)  { |n| "Last#{n}" }
    sequence(:display_name) { |n| "Person #{n}" }
    email { nil }
    phone { nil }
    title { nil }
    organization_name { nil }
    notes { nil }
    user { nil }

    trait :with_email do
      sequence(:email) { |n| "person#{n}@example.com" }
    end

    trait :with_user do
      association :user
    end

    trait :discarded do
      discarded_at { Time.current }
    end
  end
end
