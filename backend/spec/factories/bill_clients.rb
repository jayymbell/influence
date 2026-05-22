FactoryBot.define do
  factory :bill_client do
    association :bill
    association :client
    shared_at { Time.current }
  end
end
