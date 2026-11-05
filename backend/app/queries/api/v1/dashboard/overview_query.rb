
module Api
  module V1
    module Dashboard
      class OverviewQuery
        def call
          {
            employees: employee_statistics,
            average_compensation_by_currency: average_compensation_by_currency
          }
        end

        private

        def employee_statistics
          Employee.group(:employment_status).count
                  .then do |counts|
            {
              total: counts.values.sum,
              active: counts.fetch("active", 0),
              inactive: counts.fetch("inactive", 0),
              terminated: counts.fetch("terminated", 0)
            }
          end
        end

        def average_compensation_by_currency
          SalaryHistory
            .joins(:employee)
            .where(cancelled_at: nil)
            .where("salary_histories.effective_from <= ?", Date.current)
            .where(
              "salary_histories.effective_to IS NULL OR salary_histories.effective_to > ?",
              Date.current
            )
            .where(employees: { employment_status: "active" })
            .group(:currency_code)
            .average(
              "annual_base_salary + annual_bonus + annual_allowances"
            )
            .transform_values { |amount| amount&.round(2) }
        end
      end
    end
  end
end
