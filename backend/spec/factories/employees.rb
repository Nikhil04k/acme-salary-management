FactoryBot.define do
  factory :employee do
    sequence(:employee_number) { |n| "EMP#{n}" }
    sequence(:email) { |n| "employee#{n}@example.com" }

    first_name { "John" }
    last_name { "Doe" }

    association :country
    department
    job_title

    employment_status { "active" }
    hired_on { Date.new(2024, 1, 1) }
  end
end
