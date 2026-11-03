module SalaryHistories
  class CancelService
    class Error < StandardError; end

    def initialize(salary_history:, cancelled_by:)
      @salary_history = salary_history
      @cancelled_by = cancelled_by
    end

    def call
      result = nil

      @salary_history.employee.with_lock do
        @salary_history.reload

        unless @salary_history.future_scheduled?
          raise Error, "Only future scheduled salaries can be cancelled"
        end

        SalaryHistory.transaction do
          previous_salary = previous_salary_for
          next_salary = next_salary_for

          @salary_history.update!(
            cancelled_at: Time.current,
            cancelled_by: @cancelled_by
          )

          AuditLogging::CreateService.new(
            user: @cancelled_by,
            auditable: @salary_history,
            action: "cancel",
            audited_changes: @salary_history.saved_changes.except("updated_at")
          ).call

          if previous_salary
            previous_salary.update!(effective_to: next_salary&.effective_from)

            AuditLogging::CreateService.new(
              user: @cancelled_by,
              auditable: previous_salary,
              action: "update",
              audited_changes: previous_salary.saved_changes.except("updated_at")
            ).call
          end

          result = @salary_history
        end
      end

      result
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.record.errors.full_messages.to_sentence
    end

    private

    def previous_salary_for
      @salary_history.employee.salary_histories
                     .where(cancelled_at: nil)
                     .where(effective_to: @salary_history.effective_from)
                     .where.not(id: @salary_history.id)
                     .order(effective_from: :desc)
                     .first
    end

    def next_salary_for
      @salary_history.employee.salary_histories
                     .where(cancelled_at: nil)
                     .where("effective_from > ?", @salary_history.effective_from)
                     .order(effective_from: :asc)
                     .first
    end
  end
end
