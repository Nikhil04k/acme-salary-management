require "rails_helper"

RSpec.describe Country, type: :model do
  describe "validations" do
    subject(:country) do
      described_class.new(name: "India", iso_code: "IN")
    end

    it "is valid with valid attributes" do
      expect(country).to be_valid
    end

    it "requires a name" do
      country.name = nil

      expect(country).not_to be_valid
    end

    it "requires an ISO code" do
      country.iso_code = nil

      expect(country).not_to be_valid
    end

    it "accepts a two-letter uppercase ISO code" do
      country.iso_code = "IN"

      expect(country).to be_valid
    end

    it "rejects an invalid ISO code" do
      country.iso_code = "IND"

      expect(country).not_to be_valid
    end

    it "rejects duplicate ISO codes" do
      described_class.create!(name: "India", iso_code: "IN")

      duplicate = described_class.new(name: "Another India", iso_code: "IN")

      expect(duplicate).not_to be_valid
    end
  end
end
