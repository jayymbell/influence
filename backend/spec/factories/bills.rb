FactoryBot.define do
  factory :bill do
    sequence(:title) { |n| "Bill #{n}" }
    bill_number { nil }
    chamber { nil }
    session_year { nil }
    description { nil }
    notes { nil }
    tags { [] }
    status { :introduced }

    trait :house do
      chamber { :house }
      sequence(:bill_number) { |n| "HF #{n}" }
    end

    trait :senate do
      chamber { :senate }
      sequence(:bill_number) { |n| "SF #{n}" }
    end

    trait :signed do
      status { :signed }
    end

    trait :failed do
      status { :failed }
    end

    trait :with_tags do
      tags { %w[healthcare transportation] }
    end

    trait :with_session do
      session_year { 2025 }
    end
  end
end
