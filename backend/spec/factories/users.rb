FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    # Password must satisfy custom validator: min length 12, uppercase, lowercase, digit, special char
    password { "Password123!@" }
    password_confirmation { "Password123!@" }
    confirmed_at { Time.current }

    trait :admin do
      after(:create) do |user|
        admin_role = Role.find_or_create_by!(name: 'admin') do |r|
          r.description = 'Administrator'
        end
        user.roles << admin_role unless user.roles.exists?(name: 'admin')
      end
    end

    trait :with_role do
      transient do
        roles_count { 1 }
        role_name { nil }
      end

      after(:create) do |user, evaluator|
        if evaluator.role_name
          role = Role.find_or_create_by!(name: evaluator.role_name) do |r|
            r.description = "#{evaluator.role_name.capitalize} role"
          end
          user.roles << role unless user.roles.exists?(name: evaluator.role_name)
        else
          create_list(:role, evaluator.roles_count, users: [user])
        end
      end
    end
  end
end
