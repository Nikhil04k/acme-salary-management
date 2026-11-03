require "rails_helper"

RSpec.describe SalaryHistories::CreateService do
  let(:employee) { create(:employee) }
  let(:user) { create(:user) }
  let(:currency) { create(:currency) }

  let(:base_attributes) do
    {
      annual_base_salary: 600_000,
      annual_bonus: 50_000,
      annual_allowances: 20_000,
      currency_code: currency.code,
      change_reason: "Annual salary revision"
    }
  end

  def create_salary(from:, to: nil, amount: 500_000)
    create(
      :salary_history,
      employee: employee,
      created_by: user,
      currency: currency,
      annual_base_salary: amount,
      effective_from: from,
      effective_to: to
    )
  end

  def call_service(attributes)
    described_class.new(
      employee: employee,
      created_by: user,
      attributes: attributes
    ).call
  end

  describe "#call" do
    it "creates the first salary record" do
      salary = call_service(
        base_attributes.merge(
          effective_from: Date.new(2025, 1, 1)
        )
      )

      expect(salary).to be_persisted
      expect(salary.annual_base_salary).to eq(600_000)
      expect(salary.effective_to).to be_nil
    end

    it "closes the previous salary period" do
      previous = create_salary(
        from: Date.new(2025, 1, 1)
      )

      new_salary = call_service(
        base_attributes.merge(
          effective_from: Date.new(2026, 1, 1)
        )
      )

      expect(previous.reload.effective_to).to eq(Date.new(2026, 1, 1))
      expect(new_salary.effective_to).to be_nil
    end

    it "inserts a salary between existing future records" do
      previous = create_salary(
        from: Date.new(2025, 1, 1),
        to: Date.new(2027, 1, 1)
      )

      future = create_salary(
        from: Date.new(2027, 1, 1),
        amount: 700_000
      )

      new_salary = call_service(
        base_attributes.merge(
          effective_from: Date.new(2026, 1, 1)
        )
      )

      expect(previous.reload.effective_to).to eq(Date.new(2026, 1, 1))
      expect(new_salary.effective_to).to eq(Date.new(2027, 1, 1))
      expect(future.reload.effective_to).to be_nil
    end

    it "rejects duplicate effective dates" do
      create_salary(
        from: Date.new(2026, 1, 1)
      )

      expect {
        call_service(
          base_attributes.merge(
            effective_from: Date.new(2026, 1, 1)
          )
        )
      }.to raise_error(
        SalaryHistories::CreateService::Error,
        /already exists/
      )
    end

    it "does not modify cancelled salary records" do
      previous = create_salary(
        from: Date.new(2025, 1, 1),
        to: Date.new(2027, 1, 1)
      )

      future = create_salary(
        from: Date.new(2027, 1, 1),
        amount: 700_000
      )

      future.update_columns(cancelled_at: Time.current)

      new_salary = call_service(
        base_attributes.merge(
          effective_from: Date.new(2026, 1, 1)
        )
      )

      expect(previous.reload.effective_to).to eq(Date.new(2026, 1, 1))
      expect(new_salary.effective_to).to be_nil
      expect(future.reload.effective_to).to be_nil
    end

    it "rolls back the previous salary update if new salary creation fails" do
      previous = create_salary(
        from: Date.new(2025, 1, 1)
      )

      expect {
        call_service(
          base_attributes.merge(
            effective_from: Date.new(2026, 1, 1),
            annual_base_salary: -100
          )
        )
      }.to raise_error(SalaryHistories::CreateService::Error)

      expect(previous.reload.effective_to).to be_nil
    end

    it "inserts a salary before the earliest existing salary record" do
      future = create_salary(
        from: Date.new(2026, 1, 1),
        amount: 600_000
      )

      new_salary = call_service(
        base_attributes.merge(
          effective_from: Date.new(2025, 1, 1),
          annual_base_salary: 500_000
        )
      )

      expect(new_salary.effective_from).to eq(Date.new(2025, 1, 1))
      expect(new_salary.effective_to).to eq(Date.new(2026, 1, 1))

      expect(future.reload.effective_from).to eq(Date.new(2026, 1, 1))
      expect(future.effective_to).to be_nil
    end
  end
end
