FactoryBot.define do
  factory :refresh_token do
    user
    revoked_at { nil }
    expires_at { 30.days.from_now }

    initialize_with { new(attributes) }
  end
end
