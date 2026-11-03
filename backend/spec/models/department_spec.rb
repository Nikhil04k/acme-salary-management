require "rails_helper"

RSpec.describe Department, type: :model do
  describe "validations" do
    it "is valid with a name" do
      department = described_class.new(name: "Engineering")

      expect(department).to be_valid
    end

    it "requires a name" do
      department = described_class.new(name: nil)

      expect(department).not_to be_valid
    end

    it "rejects duplicate department names" do
      described_class.create!(name: "Engineering")

      duplicate = described_class.new(name: "Engineering")

      expect(duplicate).not_to be_valid
    end

    it "rejects duplicate names regardless of case" do
      described_class.create!(name: "Engineering")

      duplicate = described_class.new(name: "engineering")

      expect(duplicate).not_to be_valid
    end
  end
end
