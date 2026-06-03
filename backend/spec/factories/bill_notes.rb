FactoryBot.define do
  factory :bill_note do
    association :bill
    association :user
    title   { 'Test note' }
    content { '<p>This is a test note.</p>' }
    shared  { false }
    pinned  { false }

    trait :shared do
      shared { true }
    end

    trait :pinned do
      shared { true }
      pinned { true }
    end
  end
end
