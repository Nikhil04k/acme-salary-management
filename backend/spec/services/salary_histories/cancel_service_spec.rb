require "rails_helper"

RSpec.describe SalaryHistories::CancelService do
  let(:employee) { create(:employee) }
  let(:user) { create(:user) }
  let(:currency) { create(:currency) }

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

  def call_service(salary)
    described_class.new(
      salary_history: salary,
      cancelled_by: user
    ).call
  end

  describe "#call" do
    it "cancels a future scheduled salary" do
      salary = create_salary(
        from: Date.current + 30.days
      )

      result = call_service(salary)

      expect(result.reload.cancelled?).to be true
      expect(result.cancelled_by).to eq(user)
      expect(result.cancelled_at).to be_present
    end

    it "extends the previous salary until the next salary starts" do
      previous = create_salary(
        from: Date.new(2027, 1, 1),
        to: Date.new(2028, 1, 1)
      )

      scheduled = create_salary(
        from: Date.new(2028, 1, 1),
        to: Date.new(2029, 1, 1),
        amount: 600_000
      )

      future = create_salary(
        from: Date.new(2029, 1, 1),
        amount: 700_000
      )

      call_service(scheduled)

      expect(scheduled.reload.cancelled?).to be true
      expect(previous.reload.effective_to).to eq(Date.new(2029, 1, 1))
      expect(future.reload.effective_to).to be_nil
    end

    it "extends the previous salary indefinitely when no next salary exists" do
      previous = create_salary(
        from: Date.new(2025, 1, 1),
        to: Date.current + 30.days
      )

      scheduled = create_salary(
        from: Date.current + 30.days,
        amount: 600_000
      )

      call_service(scheduled)

      expect(scheduled.reload.cancelled?).to be true
      expect(previous.reload.effective_to).to be_nil
    end

    it "does not modify the previous salary when no previous record exists" do
      scheduled = create_salary(
        from: Date.current + 30.days
      )

      result = call_service(scheduled)

      expect(result.reload.cancelled?).to be true
    end

    it "does not allow cancelling the current salary" do
      salary = create_salary(
        from: Date.current
      )

      expect {
        call_service(salary)
      }.to raise_error(
        SalaryHistories::CancelService::Error,
        /Only future scheduled salaries/
      )
    end

    it "does not allow cancelling historical salaries" do
      salary = create_salary(
        from: Date.current - 30.days
      )

      expect {
        call_service(salary)
      }.to raise_error(
        SalaryHistories::CancelService::Error,
        /Only future scheduled salaries/
      )
    end

    it "does not allow cancelling an already cancelled salary" do
      salary = create_salary(
        from: Date.current + 30.days
      )

      salary.update_columns(cancelled_at: Time.current)

      expect {
        call_service(salary)
      }.to raise_error(
        SalaryHistories::CancelService::Error,
        /Only future scheduled salaries/
      )
    end
  end
end
