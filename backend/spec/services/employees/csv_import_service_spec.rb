
require "rails_helper"
require "tempfile"
require "csv"

RSpec.describe Employees::CsvImportService do
  let!(:country) { create(:country, iso_code: "IN", name: "India") }
  let!(:department) { create(:department, name: "Engineering") }
  let!(:job_title) { create(:job_title, name: "Software Engineer") }

  let(:headers) { described_class::HEADERS }

  def create_csv(rows, custom_headers: headers)
    file = Tempfile.new(["employees", ".csv"])

    CSV.open(file.path, "w") do |csv|
      csv << custom_headers
      rows.each { |row| csv << row }
    end

    file.rewind
    file
  end

  def valid_row(employee_number: "EMP90001", email: "rahul@example.com")
    [
      employee_number,
      "Rahul",
      "Sharma",
      email,
      "IN",
      "Engineering",
      "Software Engineer",
      "active",
      "2025-01-15",
      nil
    ]
  end

  describe "#call" do
    it "imports a valid employee" do
      file = create_csv([valid_row])

      result = described_class.new(file: file).call

      expect(result[:imported_count]).to eq(1)
      expect(result[:failed_count]).to eq(0)
      expect(Employee.find_by(employee_number: "EMP90001")).to be_present
    ensure
      file&.close!
    end

    it "rejects duplicate employee numbers within the CSV" do
      file = create_csv([
        valid_row,
        valid_row(employee_number: "EMP90001", email: "another@example.com")
      ])

      result = described_class.new(file: file).call

      expect(result[:imported_count]).to eq(1)
      expect(result[:failed_count]).to eq(1)
      expect(result[:errors].first[:errors])
        .to include("Employee number is duplicated within the CSV file")
    ensure
      file&.close!
    end

    it "rejects duplicate emails within the CSV" do
      file = create_csv([
        valid_row,
        valid_row(employee_number: "EMP90002")
      ])

      result = described_class.new(file: file).call

      expect(result[:imported_count]).to eq(1)
      expect(result[:failed_count]).to eq(1)
      expect(result[:errors].first[:errors])
        .to include("Email is duplicated within the CSV file")
    ensure
      file&.close!
    end

    it "reports missing country, department and job title" do
      row = valid_row
      row[4] = "XX"
      row[5] = "Unknown Department"
      row[6] = "Unknown Job"

      file = create_csv([row])

      result = described_class.new(file: file).call

      expect(result[:failed_count]).to eq(1)

      errors = result[:errors].first[:errors]

      expect(errors).to include(
        "Country not found",
        "Department not found",
        "Job title not found"
      )
    ensure
      file&.close!
    end

    it "rejects invalid CSV headers" do
      file = create_csv(
        [valid_row],
        custom_headers: ["employee_number", "first_name"]
      )

      expect {
        described_class.new(file: file).call
      }.to raise_error(ArgumentError, /Invalid CSV headers/)
    ensure
      file&.close!
    end

    it "rejects an invalid employee email" do
      row = valid_row
      row[3] = "invalid-email"

      file = create_csv([row])

      result = described_class.new(file: file).call

      expect(result[:failed_count]).to eq(1)
      expect(result[:errors].first[:errors]).to include("Email is invalid")
    ensure
      file&.close!
    end

    it "rejects an employee that already exists in the database" do
      create(
        :employee,
        employee_number: "EMP90001",
        email: "existing@example.com"
      )

      file = create_csv([valid_row])

      result = described_class.new(file: file).call

      expect(result[:failed_count]).to eq(1)
    ensure
      file&.close!
    end
  end
end
