module Api
  module V1
    module Dashboard
      class RecentSalaryChangesQuery
        DEFAULT_LIMIT = 10
        MAX_LIMIT = 50

        def initialize(limit: DEFAULT_LIMIT)
          @limit = [[limit.to_i, 1].max, MAX_LIMIT].min
        end

        def call
          AuditLog
            .where(auditable_type: "SalaryHistory")
            .includes(:user, auditable: :employee)
            .order(created_at: :desc, id: :desc)
            .limit(@limit)
            .map do |log|
              salary = log.auditable
              employee = salary.employee

              {
                id: log.id,
                action: log.action,
                employee: {
                  id: employee.id,
                  employee_number: employee.employee_number,
                  full_name: "#{employee.first_name} #{employee.last_name}"
                },
                performed_by: {
                  id: log.user.id,
                  email: log.user.email
                },
                audited_changes: log.audited_changes,
                created_at: log.created_at
              }
            end
        end
      end
    end
  end
end
