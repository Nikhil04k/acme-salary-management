FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2026-11-03 21:58:03" }
  end
end
