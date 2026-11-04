require "rails_helper"

RSpec.describe EmployeePolicy do
  subject(:policy) { described_class.new(user, Employee.new) }

  describe "admin permissions" do
    let(:user) { build(:user, role: "admin") }

    it "allows all employee actions" do
      expect(policy.index?).to be true
      expect(policy.show?).to be true
      expect(policy.create?).to be true
      expect(policy.update?).to be true
    end
  end

  describe "HR manager permissions" do
    let(:user) { build(:user, role: "hr_manager") }

    it "allows all employee actions" do
      expect(policy.index?).to be true
      expect(policy.show?).to be true
      expect(policy.create?).to be true
      expect(policy.update?).to be true
    end
  end

  describe "viewer permissions" do
    let(:user) { build(:user, role: "viewer") }

    it "allows viewing employees" do
      expect(policy.index?).to be true
      expect(policy.show?).to be true
    end

    it "does not allow creating or updating employees" do
      expect(policy.create?).to be false
      expect(policy.update?).to be false
    end
  end
end
