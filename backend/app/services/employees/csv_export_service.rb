
require "csv"

module Employees
  class CsvExportService
    HEADERS = [
      "Employee Number",
      "First Name",
      "Last Name",
      "Full Name",
      "Email",
      "Country",
      "Country Code",
      "Department",
      "Job Title",
      "Employment Status",
      "Hired On",
      "Terminated On"
    ].freeze

    def initialize(employees:)
      @employees = employees
    end

    def call
      CSV.generate(headers: true) do |csv|
        csv << HEADERS

        @employees.each do |employee|
          csv << [
            employee.employee_number,
            employee.first_name,
            employee.last_name,
            "#{employee.first_name} #{employee.last_name}",
            employee.email,
            employee.country.name,
            employee.country.iso_code,
            employee.department.name,
            employee.job_title.name,
            employee.employment_status,
            employee.hired_on,
            employee.terminated_on
          ]
        end
      end
    end
  end
end
