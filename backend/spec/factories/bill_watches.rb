FactoryBot.define do
  factory :bill_watch do
    association :user
    association :bill
  end
end
