FactoryBot.define do
  factory :invitation do
    association :person
    association :created_by, factory: :user

    sequence(:token_digest) { |n| Digest::SHA256.hexdigest("token#{n}") }
    sequence(:email_snapshot) { |n| "invite#{n}@example.com" }
    expires_at { 7.days.from_now }
    accepted_at { nil }
    revoked_at  { nil }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :revoked do
      revoked_at { Time.current }
    end

    trait :accepted do
      accepted_at { Time.current }
    end
  end
end
