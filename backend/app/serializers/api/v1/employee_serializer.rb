module Api
  module V1
    class EmployeeSerializer
      def initialize(employee)
        @employee = employee
      end

      def as_json
        {
          id: @employee.id,
          employee_number: @employee.employee_number,
          first_name: @employee.first_name,
          last_name: @employee.last_name,
          full_name: "#{@employee.first_name} #{@employee.last_name}",
          email: @employee.email,
          employment_status: @employee.employment_status,
          hired_on: @employee.hired_on,
          terminated_on: @employee.terminated_on,
          country: {
            id: @employee.country.id,
            name: @employee.country.name,
            iso_code: @employee.country.iso_code
          },
          department: {
            id: @employee.department.id,
            name: @employee.department.name
          },
          job_title: {
            id: @employee.job_title.id,
            name: @employee.job_title.name
          },
          created_at: @employee.created_at,
          updated_at: @employee.updated_at
        }
      end
    end
  end
end
