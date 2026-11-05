
require "rails_helper"

RSpec.describe Api::V1::Dashboard::RecentSalaryChangesQuery do
  describe "#call" do
    let(:user) { create(:user) }
    let(:employee) { create(:employee) }

    def create_salary_audit(user:, employee:, action:, created_at:)
      salary = create(
        :salary_history,
        employee: employee,
        created_by: user
      )

      create(
        :audit_log,
        user: user,
        auditable: salary,
        action: action,
        created_at: created_at
      )
    end

    before do
      AuditLog.delete_all
    end

    it "returns recent salary changes in descending order" do
      old_log = create_salary_audit(
        user: user,
        employee: create(:employee),
        action: "create",
        created_at: 3.days.ago
      )

      new_log = create_salary_audit(
        user: user,
        employee: create(:employee),
        action: "update",
        created_at: 1.day.ago
      )

      result = described_class.new.call

      expect(result.map { |item| item[:id] })
        .to eq([new_log.id, old_log.id])
    end

    it "returns 10 records by default" do
      12.times do
        create_salary_audit(
          user: user,
          employee: create(:employee),
          action: "create",
          created_at: Time.current
        )
      end

      expect(described_class.new.call.size).to eq(10)
    end

    it "supports a custom limit" do
      5.times do
        create_salary_audit(
          user: user,
          employee: create(:employee),
          action: "create",
          created_at: Time.current
        )
      end

      expect(described_class.new(limit: 3).call.size).to eq(3)
    end

    it "does not return more than 50 records" do
      expect(described_class.new(limit: 100).instance_variable_get(:@limit))
        .to eq(50)
    end

    it "includes employee and user details" do
      employee = create(:employee)

      log = create_salary_audit(
        user: user,
        employee: employee,
        action: "create",
        created_at: Time.current
      )

      result = described_class.new.call.first

      expect(result[:id]).to eq(log.id)
      expect(result[:action]).to eq("create")
      expect(result[:employee][:id]).to eq(employee.id)
      expect(result[:employee][:employee_number]).to eq(employee.employee_number)
      expect(result[:performed_by][:email]).to eq(user.email)
      expect(result[:created_at]).to eq(log.created_at)
    end

    it "returns an empty array when no audit logs exist" do
      AuditLog.delete_all

      expect(described_class.new.call).to eq([])
    end
  end
end
