
module Api
  module V1
    module Dashboard
      class SalaryAnalyticsQuery
        def call
          {
            by_currency: by_currency,
            by_department: by_department
          }
        end

        private

        def current_salaries
          SalaryHistory
            .joins(:employee)
            .where(cancelled_at: nil)
            .where("salary_histories.effective_from <= ?", Date.current)
            .where(
              "salary_histories.effective_to IS NULL OR salary_histories.effective_to > ?",
              Date.current
            )
            .where(employees: { employment_status: "active" })
        end

        def compensation_sql
          "annual_base_salary + annual_bonus + annual_allowances"
        end

        def by_currency
          current_salaries
            .group(:currency_code)
            .select(
              "currency_code",
              "COUNT(DISTINCT salary_histories.employee_id) AS employee_count",
              "AVG(#{compensation_sql}) AS average_compensation",
              "MIN(#{compensation_sql}) AS minimum_compensation",
              "MAX(#{compensation_sql}) AS maximum_compensation",
              "SUM(#{compensation_sql}) AS total_compensation"
            )
            .map do |record|
              {
                currency: record.currency_code,
                employee_count: record.employee_count,
                average_compensation: record.average_compensation.to_d.round(2),
                minimum_compensation: record.minimum_compensation.to_d,
                maximum_compensation: record.maximum_compensation.to_d,
                total_compensation: record.total_compensation.to_d.round(2)
              }
            end
        end

        def by_department
          current_salaries
            .joins(employee: :department)
            .group("departments.name", :currency_code)
            .average(compensation_sql)
            .map do |(department, currency), average|
              {
                department: department,
                currency: currency,
                average_compensation: average.to_d.round(2)
              }
            end
        end
      end
    end
  end
end
