class User < ApplicationRecord
  ROLES = %w[admin hr_manager viewer].freeze

  has_many :salary_histories,
         foreign_key: :created_by_id,
         dependent: :restrict_with_error

  has_many :audit_logs, dependent: :restrict_with_error

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :role, presence: true, inclusion: { in: ROLES }
end
