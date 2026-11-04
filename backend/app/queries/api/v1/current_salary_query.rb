module Api
  module V1
    class CurrentSalaryQuery
      def initialize(employee, date: Date.current)
        @employee = employee
        @date = date
      end

      def call
        @employee.salary_histories
                 .select do |salary|
          salary.cancelled_at.nil? &&
            salary.effective_from <= @date &&
            (salary.effective_to.nil? || salary.effective_to > @date)
        end
                 .max_by(&:effective_from)
      end
    end
  end
end
