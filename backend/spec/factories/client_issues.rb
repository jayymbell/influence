FactoryBot.define do
  factory :client_issue do
    association :client
    association :issue
    is_primary { false }
    shared_at  { Time.current }
  end
end
