FactoryBot.define do
  factory :bill_issue do
    association :bill
    association :issue
    added_at { Time.current }
  end
end
