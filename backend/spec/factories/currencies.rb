FactoryBot.define do
  factory :currency do
    code { "INR" }
    name { "Indian Rupee" }
    decimal_places { 2 }
  end
end
