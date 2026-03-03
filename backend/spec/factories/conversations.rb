FactoryBot.define do
  factory :conversation do
    association :user
    title { "Test conversation" }

    trait :with_messages do
      transient do
        messages_count { 2 }
      end

      after(:create) do |conversation, evaluator|
        evaluator.messages_count.times do |i|
          create(:message, conversation: conversation, role: i.even? ? "user" : "assistant")
        end
      end
    end
  end
end
