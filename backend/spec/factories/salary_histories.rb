
FactoryBot.define do
  factory :salary_history do
    association :employee
    association :created_by, factory: :user

    currency do
      Currency.find_or_create_by!(code: "INR") do |record|
        record.name = "Indian Rupee"
        record.decimal_places = 2
      end
    end

    annual_base_salary { 500000 }
    annual_bonus { 0 }
    annual_allowances { 0 }
    effective_from { Date.current }
    effective_to { nil }
    change_reason { "Initial salary" }

    trait :cancelled do
      cancelled_at { Time.current }
      association :cancelled_by, factory: :user
    end
  end
end
