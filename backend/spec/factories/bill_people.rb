FactoryBot.define do
  factory :bill_person do
    association :bill
    association :person
  end
end
