FactoryBot.define do
  factory :message do
    association :conversation
    role { "user" }
    sequence(:content) { |n| "Message content #{n}" }
  end
end
