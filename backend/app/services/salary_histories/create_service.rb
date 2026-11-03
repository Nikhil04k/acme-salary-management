module SalaryHistories
  class CreateService
    class Error < StandardError; end

    def initialize(employee:, created_by:, attributes:)
      @employee = employee
      @created_by = created_by
      @attributes = attributes
    end

    def call
      @employee.with_lock do
        create_salary_history!
      end
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.record.errors.full_messages.to_sentence
    end

    private

    def create_salary_history!
      effective_from = @attributes[:effective_from]

      raise Error, "Effective date is required" if effective_from.blank?

      effective_from = effective_from.to_date

      if SalaryHistory.exists?(
        employee_id: @employee.id,
        effective_from: effective_from,
        cancelled_at: nil
      )
        raise Error, "A salary record already exists for this effective date"
      end

      previous_salary = previous_salary_for(effective_from)
      next_salary = next_salary_for(effective_from)

      salary_history = nil

      SalaryHistory.transaction do
        if previous_salary
          previous_salary.update!(
            effective_to: effective_from
          )
        end

        attributes = @attributes.except(:effective_to).merge(
          employee: @employee,
          created_by: @created_by,
          effective_from: effective_from,
          effective_to: next_salary&.effective_from
        )

        salary_history = SalaryHistory.create!(attributes)
      end

      salary_history
    end

    def previous_salary_for(date)
      @employee.salary_histories
               .where(cancelled_at: nil)
               .where("effective_from < ?", date)
               .where("effective_to IS NULL OR effective_to > ?", date)
               .order(effective_from: :desc)
               .first
    end

    def next_salary_for(date)
      @employee.salary_histories
               .where(cancelled_at: nil)
               .where("effective_from > ?", date)
               .order(effective_from: :asc)
               .first
    end
  end
end
