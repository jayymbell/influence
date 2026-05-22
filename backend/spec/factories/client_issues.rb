FactoryBot.define do
  factory :client_issue do
    association :client
    association :issue
    shared_at  { Time.current }
  end
end
