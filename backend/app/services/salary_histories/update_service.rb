module SalaryHistories
  class UpdateService
    class Error < StandardError; end

    EDITABLE_ATTRIBUTES = %i[
      annual_base_salary
      annual_bonus
      annual_allowances
      currency_code
      change_reason
    ].freeze

    IMMUTABLE_ATTRIBUTES = %i[
      effective_from
      effective_to
      employee_id
      created_by_id
      cancelled_at
      cancelled_by_id
    ].freeze

    def initialize(salary_history:, updated_by:, attributes:)
      @salary_history = salary_history
      @updated_by = updated_by
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      result = nil

      @salary_history.employee.with_lock do
        @salary_history.reload

        raise Error, "Only future scheduled salaries can be edited" unless @salary_history.editable?

        forbidden_attributes = @attributes.keys & IMMUTABLE_ATTRIBUTES

        if forbidden_attributes.any?
          raise Error, "Cannot modify: #{forbidden_attributes.join(', ')}"
        end

        editable_attributes = @attributes.slice(*EDITABLE_ATTRIBUTES)

        if editable_attributes.empty?
          raise Error, "No editable attributes provided"
        end

        @salary_history.update!(editable_attributes)

        AuditLogging::CreateService.new(
          user: @updated_by,
          auditable: @salary_history,
          action: "update",
          audited_changes: @salary_history.saved_changes.except("updated_at")
        ).call

        result = @salary_history
      end

      result
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.record.errors.full_messages.to_sentence
    end
  end
end
