require "rails_helper"

RSpec.describe SalaryHistories::UpdateService do
  let(:employee) { create(:employee) }
  let(:user) { create(:user) }
  let(:currency) { create(:currency) }

  let(:future_date) { Date.current + 30.days }

  let(:salary_history) do
    create(
      :salary_history,
      employee: employee,
      created_by: user,
      currency: currency,
      annual_base_salary: 500_000,
      effective_from: future_date
    )
  end

  def call_service(attributes)
    described_class.new(
      salary_history: salary_history,
      updated_by: user,
      attributes: attributes
    ).call
  end

  describe "#call" do
    it "updates a future scheduled salary" do
      updated_salary = call_service(
        annual_base_salary: 700_000,
        annual_bonus: 50_000,
        change_reason: "Promotion"
      )

      expect(updated_salary.annual_base_salary).to eq(700_000)
      expect(updated_salary.annual_bonus).to eq(50_000)
      expect(updated_salary.change_reason).to eq("Promotion")
    end

    it "does not allow editing the current salary" do
      salary_history.update_columns(
        effective_from: Date.current
      )

      expect {
        call_service(annual_base_salary: 700_000)
      }.to raise_error(
        SalaryHistories::UpdateService::Error,
        /Only future scheduled salaries/
      )
    end

    it "does not allow editing historical salary records" do
      salary_history.update_columns(
        effective_from: Date.current - 30.days
      )

      expect {
        call_service(annual_base_salary: 700_000)
      }.to raise_error(
        SalaryHistories::UpdateService::Error,
        /Only future scheduled salaries/
      )
    end

    it "does not allow editing cancelled salary records" do
      salary_history.update_columns(
        cancelled_at: Time.current
      )

      expect {
        call_service(annual_base_salary: 700_000)
      }.to raise_error(
        SalaryHistories::UpdateService::Error,
        /Only future scheduled salaries/
      )
    end

    it "does not allow changing the effective date" do
      expect {
        call_service(
          effective_from: Date.current + 60.days
        )
      }.to raise_error(
        SalaryHistories::UpdateService::Error,
        /Cannot modify: effective_from/
      )
    end

    it "rejects negative salary amounts" do
      expect {
        call_service(
          annual_base_salary: -100
        )
      }.to raise_error(
        SalaryHistories::UpdateService::Error
      )

      expect(salary_history.reload.annual_base_salary).to eq(500_000)
    end

    it "creates an audit log when salary is updated" do
      expect {
        call_service(annual_base_salary: 700000)
      }.to change(AuditLog, :count).by(1)

      audit_log = AuditLog.last

      expect(audit_log.action).to eq("update")
      expect(audit_log.user).to eq(user)
      expect(audit_log.auditable).to eq(salary_history)
      expect(audit_log.audited_changes).to have_key("annual_base_salary")
    end

    it "rolls back salary update if audit logging fails" do
      original_salary = salary_history.annual_base_salary

      allow(AuditLog).to receive(:create!).and_raise(
        ActiveRecord::RecordInvalid.new(AuditLog.new)
      )

      expect {
        call_service(annual_base_salary: 700000)
      }.to raise_error(SalaryHistories::UpdateService::Error)

      expect(salary_history.reload.annual_base_salary).to eq(original_salary)
      expect(AuditLog.count).to eq(0)
    end
  end
end
