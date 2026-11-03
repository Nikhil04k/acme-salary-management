require "rails_helper"

RSpec.describe Employee, type: :model do
  let(:country) do
    Country.create!(name: "India", iso_code: "IN")
  end

  let(:department) do
    Department.create!(name: "Engineering")
  end

  let(:job_title) do
    JobTitle.create!(name: "Ruby Developer")
  end

  let(:employee) do
    Employee.new(
      employee_number: "ACME-00001",
      first_name: "Rahul",
      last_name: "Sharma",
      email: "rahul@acme.com",
      country: country,
      department: department,
      job_title: job_title,
      employment_status: "active",
      hired_on: Date.new(2025, 1, 1)
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(employee).to be_valid
    end

    it "requires employee number" do
      employee.employee_number = nil

      expect(employee).not_to be_valid
    end

    it "requires first name" do
      employee.first_name = nil

      expect(employee).not_to be_valid
    end

    it "requires last name" do
      employee.last_name = nil

      expect(employee).not_to be_valid
    end

    it "requires email" do
      employee.email = nil

      expect(employee).not_to be_valid
    end

    it "validates email format" do
      employee.email = "invalid-email"

      expect(employee).not_to be_valid
    end

    it "does not allow duplicate employee numbers" do
      employee.save!

      duplicate = employee.dup
      duplicate.email = "another@acme.com"

      expect(duplicate).not_to be_valid
    end

    it "does not allow duplicate emails" do
      employee.save!

      duplicate = employee.dup
      duplicate.employee_number = "ACME-00002"

      expect(duplicate).not_to be_valid
    end

    it "does not allow invalid employment status" do
      employee.employment_status = "pending"

      expect(employee).not_to be_valid
    end

    it "allows active, inactive and terminated statuses" do
      Employee::STATUSES.each do |status|
        employee.employment_status = status
        employee.terminated_on = Date.new(2026, 1, 1) if status == "terminated"

        expect(employee).to be_valid
      end
    end
  end

  describe "termination date validation" do
    it "does not allow termination date before hire date" do
      employee.terminated_on = Date.new(2024, 12, 31)
      employee.employment_status = "terminated"

      expect(employee).not_to be_valid
    end

    it "does not allow termination date for active employees" do
      employee.terminated_on = Date.new(2026, 1, 1)

      expect(employee).not_to be_valid
    end

    it "allows termination date for terminated employees" do
      employee.employment_status = "terminated"
      employee.terminated_on = Date.new(2026, 1, 1)

      expect(employee).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a country" do
      expect(described_class.reflect_on_association(:country).macro).to eq(:belongs_to)
    end

    it "belongs to a department" do
      expect(described_class.reflect_on_association(:department).macro).to eq(:belongs_to)
    end

    it "belongs to a job title" do
      expect(described_class.reflect_on_association(:job_title).macro).to eq(:belongs_to)
    end
  end
end
