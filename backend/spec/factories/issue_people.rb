FactoryBot.define do
  factory :issue_person do
    association :issue
    association :person
  end
end
