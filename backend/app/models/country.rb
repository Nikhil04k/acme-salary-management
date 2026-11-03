class Country < ApplicationRecord
  has_many :employees, dependent: :restrict_with_error

  validates :name, presence: true
  validates :iso_code,
            presence: true,
            uniqueness: true,
            format: { with: /\A[A-Z]{2}\z/ }
end
