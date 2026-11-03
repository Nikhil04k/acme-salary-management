require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      user = described_class.new(
        email: "hr@acme.com",
        password: "Password@123",
        role: "hr_manager"
      )

      expect(user).to be_valid
    end

    it "requires an email" do
      user = described_class.new(
        email: nil,
        password: "Password@123",
        role: "hr_manager"
      )

      expect(user).not_to be_valid
    end

    it "requires a valid role" do
      user = described_class.new(
        email: "test@acme.com",
        password: "Password@123",
        role: "super_admin"
      )

      expect(user).not_to be_valid
    end

    it "allows admin role" do
      user = described_class.new(
        email: "admin@acme.com",
        password: "Password@123",
        role: "admin"
      )

      expect(user).to be_valid
    end

    it "allows viewer role" do
      user = described_class.new(
        email: "viewer@acme.com",
        password: "Password@123",
        role: "viewer"
      )

      expect(user).to be_valid
    end
  end

  describe "authentication" do
    let(:user) do
      described_class.create!(
        email: "hr@example.com",
        password: "Password@123",
        role: "hr_manager"
      )
    end

    it "authenticates with the correct password" do
      expect(user.valid_password?("Password@123")).to be true
    end

    it "does not authenticate with an incorrect password" do
      expect(user.valid_password?("WrongPassword")).to be false
    end
  end
end
