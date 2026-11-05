
require "csv"

module Employees
  class CsvImportService
    HEADERS = %w[
      employee_number
      first_name
      last_name
      email
      country_code
      department
      job_title
      employment_status
      hired_on
      terminated_on
    ].freeze

    def initialize(file:)
      @file = file
      @imported_count = 0
      @failed_rows = []
      @seen_employee_numbers = {}
      @seen_emails = {}
    end

    def call
      validate_file!

      CSV.foreach(@file.path, headers: true).with_index(2) do |row, row_number|
        import_row(row, row_number)
      end

      {
        total_rows: @imported_count + @failed_rows.size,
        imported_count: @imported_count,
        failed_count: @failed_rows.size,
        errors: @failed_rows
      }
    rescue CSV::MalformedCSVError => e
      raise ArgumentError, "Invalid CSV format: #{e.message}"
    end

    private

    def validate_file!
      raise ArgumentError, "CSV file is required" unless @file

      headers = CSV.open(@file.path, &:readline)

      unless headers && headers.map(&:strip) == HEADERS
        raise ArgumentError, "Invalid CSV headers. Expected: #{HEADERS.join(', ')}"
      end
    rescue CSV::MalformedCSVError, EOFError => e
      raise ArgumentError, "Invalid CSV format: #{e.message}"
    end

    def import_row(row, row_number)
      attributes = row.to_h.transform_keys { |key| key.to_s.strip }
                      .transform_values { |value| value&.strip }

      errors = []

      employee_number = attributes["employee_number"]
      email = attributes["email"]&.downcase

      check_duplicate(
        @seen_employee_numbers,
        employee_number,
        "Employee number",
        errors
      )

      check_duplicate(
        @seen_emails,
        email,
        "Email",
        errors
      )

      country = Country.find_by(
        iso_code: attributes["country_code"]&.upcase
      )

      department = Department.find_by(
        "LOWER(name) = ?",
        attributes["department"]&.downcase
      )

      job_title = JobTitle.find_by(
        "LOWER(name) = ?",
        attributes["job_title"]&.downcase
      )

      errors << "Country not found" unless country
      errors << "Department not found" unless department
      errors << "Job title not found" unless job_title

      if errors.any?
        add_failed_row(row_number, employee_number, errors)
        return
      end

      employee = Employee.new(
        employee_number: employee_number,
        first_name: attributes["first_name"],
        last_name: attributes["last_name"],
        email: attributes["email"],
        country: country,
        department: department,
        job_title: job_title,
        employment_status: attributes["employment_status"],
        hired_on: attributes["hired_on"],
        terminated_on: attributes["terminated_on"].presence
      )

      if employee.save
        @imported_count += 1
      else
        add_failed_row(
          row_number,
          employee_number,
          employee.errors.full_messages
        )
      end
    end

    def check_duplicate(seen, value, label, errors)
      return if value.blank?

      if seen[value]
        errors << "#{label} is duplicated within the CSV file"
      else
        seen[value] = true
      end
    end

    def add_failed_row(row_number, employee_number, errors)
      @failed_rows << {
        row: row_number,
        employee_number: employee_number,
        errors: errors
      }
    end
  end
end
