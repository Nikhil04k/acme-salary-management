require "rails_helper"

RSpec.describe SalaryHistory, type: :model do
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
    Employee.create!(
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

  let(:user) do
    User.create!(
      email: "hr@acme.com",
      password: "Password@123",
      role: "hr_manager"
    )
  end

  let(:currency) do
    Currency.create!(
      code: "INR",
      name: "Indian Rupee",
      decimal_places: 2
    )
  end

  let(:salary_history) do
    SalaryHistory.new(
      employee: employee,
      created_by: user,
      currency: currency,
      annual_base_salary: 600_000,
      annual_bonus: 50_000,
      annual_allowances: 25_000,
      effective_from: Date.new(2025, 1, 1),
      change_reason: "Initial salary"
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(salary_history).to be_valid
    end

    it "requires annual base salary" do
      salary_history.annual_base_salary = nil

      expect(salary_history).not_to be_valid
    end

    it "does not allow negative base salary" do
      salary_history.annual_base_salary = -100

      expect(salary_history).not_to be_valid
    end

    it "allows zero annual bonus" do
      salary_history.annual_bonus = 0

      expect(salary_history).to be_valid
    end

    it "does not allow negative annual bonus" do
      salary_history.annual_bonus = -100

      expect(salary_history).not_to be_valid
    end

    it "allows zero annual allowances" do
      salary_history.annual_allowances = 0

      expect(salary_history).to be_valid
    end

    it "does not allow negative annual allowances" do
      salary_history.annual_allowances = -100

      expect(salary_history).not_to be_valid
    end

    it "requires effective from date" do
      salary_history.effective_from = nil

      expect(salary_history).not_to be_valid
    end

    it "does not allow effective to before effective from" do
      salary_history.effective_to = Date.new(2024, 12, 31)

      expect(salary_history).not_to be_valid
    end

    it "does not allow effective to equal effective from" do
      salary_history.effective_to = Date.new(2025, 1, 1)

      expect(salary_history).not_to be_valid
    end

    it "allows null effective to date" do
      salary_history.effective_to = nil

      expect(salary_history).to be_valid
    end

    it "allows a future effective from date" do
      salary_history.effective_from = Date.new(2027, 1, 1)

      expect(salary_history).to be_valid
    end

    it "validates change reason length" do
      salary_history.change_reason = "A" * 501

      expect(salary_history).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to an employee" do
      expect(described_class.reflect_on_association(:employee).macro).to eq(:belongs_to)
    end

    it "belongs to a user through created_by" do
      association = described_class.reflect_on_association(:created_by)

      expect(association.macro).to eq(:belongs_to)
      expect(association.class_name).to eq("User")
    end

    it "belongs to a currency through currency_code" do
      association = described_class.reflect_on_association(:currency)

      expect(association.macro).to eq(:belongs_to)
      expect(association.foreign_key).to eq("currency_code")
      expect(association.options[:primary_key]).to eq(:code)
    end
  end

  describe "salary period overlap validation" do
    let(:employee) { create(:employee) }
    let(:user) { create(:user) }
    let(:currency) { create(:currency) }

    def create_salary_history(employee:, user:, currency:, from:, to: nil)
      SalaryHistory.create!(
        employee: employee,
        created_by: user,
        currency: currency,
        annual_base_salary: 500_000,
        annual_bonus: 0,
        annual_allowances: 0,
        effective_from: from,
        effective_to: to
      )
    end

    it "allows consecutive salary periods" do
      create_salary_history(
        employee: employee,
        user: user,
        currency: currency,
        from: Date.new(2025, 1, 1),
        to: Date.new(2026, 1, 1)
      )

      salary = build(
        :salary_history,
        employee: employee,
        created_by: user,
        currency: currency,
        effective_from: Date.new(2026, 1, 1),
        effective_to: Date.new(2027, 1, 1)
      )

      expect(salary).to be_valid
    end

    it "rejects overlapping salary periods" do
      create_salary_history(
        employee: employee,
        user: user,
        currency: currency,
        from: Date.new(2025, 1, 1),
        to: Date.new(2027, 1, 1)
      )

      salary = build(
        :salary_history,
        employee: employee,
        created_by: user,
        currency: currency,
        effective_from: Date.new(2026, 1, 1),
        effective_to: Date.new(2028, 1, 1)
      )

      expect(salary).not_to be_valid
      expect(salary.errors[:base]).to include(
        "Salary period overlaps with an existing salary record"
      )
    end

    it "rejects overlap with an open-ended salary period" do
      create_salary_history(
        employee: employee,
        user: user,
        currency: currency,
        from: Date.new(2025, 1, 1)
      )

      salary = build(
        :salary_history,
        employee: employee,
        created_by: user,
        currency: currency,
        effective_from: Date.new(2026, 1, 1)
      )

      expect(salary).not_to be_valid
    end

    it "ignores cancelled salary records" do
      existing_salary = create_salary_history(
        employee: employee,
        user: user,
        currency: currency,
        from: Date.new(2025, 1, 1)
      )

      existing_salary.update_columns(cancelled_at: Time.current)

      salary = build(
        :salary_history,
        employee: employee,
        created_by: user,
        currency: currency,
        effective_from: Date.new(2026, 1, 1)
      )

      expect(salary).to be_valid
    end

    it "does not consider the same record as overlapping when updating it" do
      existing_salary = create_salary_history(
        employee: employee,
        user: user,
        currency: currency,
        from: Date.new(2025, 1, 1),
        to: Date.new(2026, 1, 1)
      )

      existing_salary.effective_to = Date.new(2026, 6, 1)

      expect(existing_salary).to be_valid
    end
  end
end
