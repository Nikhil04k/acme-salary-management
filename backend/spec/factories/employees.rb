FactoryBot.define do
  factory :employee do
    sequence(:employee_number) { |n| "EMP#{n}_#{SecureRandom.hex(4)}" }
sequence(:email) { |n| "employee#{n}_#{SecureRandom.hex(4)}@example.com" }

    first_name { "John" }
    last_name { "Doe" }

    country do
      Country.find_or_create_by!(iso_code: "IN") do |record|
        record.name = "India"
      end
    end

    department do
      Department.find_or_create_by!(name: "Engineering")
    end

    job_title do
      JobTitle.find_or_create_by!(name: "Software Engineer")
    end

    employment_status { "active" }
    hired_on { Date.new(2024, 1, 1) }
  end
end
