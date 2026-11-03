FactoryBot.define do
  factory :audit_log do
    user { nil }
    auditable { nil }
    action { "MyString" }
    audited_changes { "" }
  end
end
