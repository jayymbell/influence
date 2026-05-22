FactoryBot.define do
  factory :issue do
    sequence(:title) { |n| "Issue #{n}" }
    description { nil }
    notes { nil }
    tags { [] }
    status { :active }
    association :client

    trait :inactive do
      status { :inactive }
    end

    trait :closed do
      status { :closed }
      closed_at { Time.current }
    end

    trait :with_tags do
      tags { %w[healthcare transportation] }
    end
  end
end
