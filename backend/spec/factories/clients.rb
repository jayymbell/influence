FactoryBot.define do
  factory :client do
    sequence(:legal_name)   { |n| "Client Legal Name #{n}" }
    sequence(:display_name) { |n| "Client #{n}" }

    trait :discarded do
      discarded_at    { Time.current }
      deactivated_at  { Time.current }
    end
  end
end
