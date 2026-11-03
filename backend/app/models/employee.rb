class Employee < ApplicationRecord
  STATUSES = %w[active inactive terminated].freeze

  belongs_to :country
  belongs_to :department
  belongs_to :job_title

  validates :employee_number,
            presence: true,
            uniqueness: true

  validates :first_name, :last_name, :email, :hired_on,
            presence: true

  validates :email,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :employment_status,
            presence: true,
            inclusion: { in: STATUSES }

  validate :termination_date_must_be_valid

  private

  def termination_date_must_be_valid
    return if terminated_on.blank?

    if hired_on.present? && terminated_on < hired_on
      errors.add(:terminated_on, "cannot be before the hire date")
    end

    if employment_status != "terminated"
      errors.add(:terminated_on, "is only allowed for terminated employees")
    end
  end
end
