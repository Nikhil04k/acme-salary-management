require "rails_helper"

RSpec.describe AuditLog, type: :model do
  let(:user) { create(:user) }
  let(:employee) { create(:employee) }

  let(:valid_attributes) do
    {
      user: user,
      auditable: employee,
      action: "create",
      audited_changes: {
        "first_name" => [nil, "Rahul"]
      },
      created_at: Time.current
    }
  end

  describe "associations" do
    it "belongs to a user" do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it "belongs to an auditable record polymorphically" do
      association = described_class.reflect_on_association(:auditable)

      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:polymorphic]).to be true
    end

    it "allows a user to have many audit logs" do
      association = User.reflect_on_association(:audit_logs)

      expect(association.macro).to eq(:has_many)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      audit_log = described_class.new(valid_attributes)

      expect(audit_log).to be_valid
    end

    it "requires an action" do
      audit_log = described_class.new(valid_attributes.merge(action: nil))

      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:action]).to include("can't be blank")
    end

    it "only allows supported actions" do
      audit_log = described_class.new(valid_attributes.merge(action: "delete"))

      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:action]).to be_present
    end

    it "requires audited changes" do
      audit_log = described_class.new(valid_attributes.merge(audited_changes: nil))

      expect(audit_log).not_to be_valid
    end
  end

  describe "immutability" do
    it "prevents updating an existing audit log" do
      audit_log = described_class.create!(valid_attributes)

      expect {
        audit_log.update!(action: "update")
      }.to raise_error(ActiveRecord::ReadOnlyRecord, "Audit logs cannot be modified")
    end

    it "prevents deleting an existing audit log" do
      audit_log = described_class.create!(valid_attributes)

      expect {
        audit_log.destroy!
      }.to raise_error(ActiveRecord::ReadOnlyRecord, "Audit logs cannot be deleted")
    end
  end
end
