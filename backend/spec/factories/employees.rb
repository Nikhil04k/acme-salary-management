FactoryBot.define do
  factory :employee do
    sequence(:employee_number) { |n| "EMP#{n}" }
    sequence(:email) { |n| "employee#{n}@acme.com" }

    first_name { "Rahul" }
    last_name { "Sharma" }

    association :country
    association :department
    association :job_title

    employment_status { "active" }
    hired_on { Date.new(2024, 1, 1) }
  end
end
