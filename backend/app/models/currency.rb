class Currency < ApplicationRecord
  self.primary_key = :code

  has_many :salary_histories,
           foreign_key: :currency_code,
           primary_key: :code,
           dependent: :restrict_with_error

  validates :code,
            presence: true,
            uniqueness: true,
            format: { with: /\A[A-Z]{3}\z/ }

  validates :name, presence: true

  validates :decimal_places,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 4
            }
end
