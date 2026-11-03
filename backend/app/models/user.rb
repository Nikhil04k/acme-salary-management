class User < ApplicationRecord
  ROLES = %w[admin hr_manager viewer].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :role, presence: true, inclusion: { in: ROLES }
end
