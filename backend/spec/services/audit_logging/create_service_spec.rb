require "rails_helper"

RSpec.describe AuditLogging::CreateService do
  let(:user) { create(:user) }
  let(:employee) { create(:employee) }

  let(:audited_changes) do
    {
      "first_name" => [nil, "Rahul"]
    }
  end

  def call_service(action: "create", changes: audited_changes)
    described_class.new(
      user: user,
      auditable: employee,
      action: action,
      audited_changes: changes
    ).call
  end

  describe "#call" do
    it "creates an audit log" do
      expect {
        call_service
      }.to change(AuditLog, :count).by(1)
    end

    it "associates the audit log with the user" do
      audit_log = call_service

      expect(audit_log.user).to eq(user)
    end

    it "associates the audit log with the auditable record" do
      audit_log = call_service

      expect(audit_log.auditable).to eq(employee)
      expect(audit_log.auditable_type).to eq("Employee")
    end

    it "stores the action and audited changes" do
      audit_log = call_service

      expect(audit_log.action).to eq("create")
      expect(audit_log.audited_changes).to eq(audited_changes)
    end

    it "stores the creation timestamp" do
      audit_log = call_service

      expect(audit_log.created_at).to be_present
    end

    it "rejects unsupported actions" do
      expect {
        call_service(action: "delete")
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "rejects empty audited changes" do
      expect {
        call_service(changes: {})
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
