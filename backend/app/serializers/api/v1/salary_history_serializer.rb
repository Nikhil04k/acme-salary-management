module Api
  module V1
    class SalaryHistorySerializer
      def initialize(salary_history)
        @salary_history = salary_history
      end

      def as_json
        {
          id: @salary_history.id,
          annual_base_salary: @salary_history.annual_base_salary,
          annual_bonus: @salary_history.annual_bonus,
          annual_allowances: @salary_history.annual_allowances,
          currency: {
            code: @salary_history.currency.code,
            name: @salary_history.currency.name
          },
          effective_from: @salary_history.effective_from,
          effective_to: @salary_history.effective_to,
          change_reason: @salary_history.change_reason,
          created_at: @salary_history.created_at
        }
      end
    end
  end
end
