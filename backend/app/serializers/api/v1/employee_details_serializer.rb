module Api
  module V1
    class EmployeeDetailsSerializer
      def initialize(employee)
        @employee = employee
      end

      def as_json
        current_salary = CurrentSalaryQuery.new(@employee).call

        salary_histories = @employee.salary_histories
                             .select { |salary| salary.cancelled_at.nil? }
                             .sort_by(&:effective_from)
                             .reverse

        {
          employee: EmployeeSerializer.new(@employee).as_json,
          current_salary: current_salary.present? ?
            SalaryHistorySerializer.new(current_salary).as_json : nil,
          salary_history: salary_histories.map do |salary|
            SalaryHistorySerializer.new(salary).as_json
          end
        }
      end
    end
  end
end
