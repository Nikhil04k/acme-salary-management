class SalaryHistory < ApplicationRecord
  belongs_to :employee

  belongs_to :created_by,
             class_name: "User",
             foreign_key: :created_by_id

  belongs_to :currency,
             foreign_key: :currency_code,
             primary_key: :code

  belongs_to :cancelled_by,
           class_name: "User",
           optional: true,
           foreign_key: :cancelled_by_id

  validates :annual_base_salary,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validates :annual_bonus,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validates :annual_allowances,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validates :effective_from, presence: true

  validates :change_reason, length: { maximum: 500 }

  validate :effective_to_must_be_after_effective_from
  validate :effective_period_must_not_overlap

  def cancelled?
    cancelled_at.present?
  end

  def future_scheduled?
    effective_from > Date.current && !cancelled?
  end

  def editable?
    future_scheduled?
  end

  private

  def effective_to_must_be_after_effective_from
    return if effective_to.blank? || effective_from.blank?

    if effective_to <= effective_from
      errors.add(:effective_to, "must be after the effective start date")
    end
  end

  def effective_period_must_not_overlap
    return if employee_id.blank? || effective_from.blank?

    overlapping_records = employee.salary_histories
                                  .where(cancelled_at: nil)
                                  .where.not(id: id)

    if effective_to.present?
      overlapping_records = overlapping_records.where(
        "effective_from < ?", effective_to
      )
    end

    overlapping_records = overlapping_records.where(
      "effective_to IS NULL OR effective_to > ?", effective_from
    )

    if overlapping_records.exists?
      errors.add(:base, "Salary period overlaps with an existing salary record")
    end
  end
end
