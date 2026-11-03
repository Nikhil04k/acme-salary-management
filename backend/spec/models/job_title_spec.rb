require "rails_helper"

RSpec.describe JobTitle, type: :model do
  describe "validations" do
    it "is valid with a name" do
      job_title = described_class.new(name: "Software Engineer")

      expect(job_title).to be_valid
    end

    it "requires a name" do
      job_title = described_class.new(name: nil)

      expect(job_title).not_to be_valid
    end

    it "rejects duplicate job titles" do
      described_class.create!(name: "Software Engineer")

      duplicate = described_class.new(name: "Software Engineer")

      expect(duplicate).not_to be_valid
    end

    it "rejects duplicate names regardless of case" do
      described_class.create!(name: "Software Engineer")

      duplicate = described_class.new(name: "software engineer")

      expect(duplicate).not_to be_valid
    end
  end
end
