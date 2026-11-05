
FactoryBot.define do
  factory :audit_log do
    association :user
    association :auditable, factory: :salary_history

    action { "create" }

    audited_changes do
      {
        "annual_base_salary" => [nil, "500000.0"],
        "currency_code" => [nil, "INR"]
      }
    end

    created_at { Time.current }
  end
end
