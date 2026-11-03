FactoryBot.define do
  factory :salary_history do
    association :employee
    association :created_by, factory: :user
    association :currency

    annual_base_salary { 500_000 }
    annual_bonus { 0 }
    annual_allowances { 0 }

    effective_from { Date.current }
    effective_to { nil }

    change_reason { "Initial salary assignment" }
  end
end
