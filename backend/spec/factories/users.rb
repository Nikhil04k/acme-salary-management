FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@acme.com" }
    password { "Password@123" }
    password_confirmation { password }
    role { "hr_manager" }
  end
end
