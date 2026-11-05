FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}_#{SecureRandom.hex(4)}@acme.com" }
    password { "Password@123" }
    password_confirmation { password }
    role { "hr_manager" }
  end
end
