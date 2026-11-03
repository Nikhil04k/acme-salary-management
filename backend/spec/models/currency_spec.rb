require "rails_helper"

RSpec.describe Currency, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      currency = described_class.new(
        code: "INR",
        name: "Indian Rupee",
        decimal_places: 2
      )

      expect(currency).to be_valid
    end

    it "requires a code" do
      currency = described_class.new(
        name: "Indian Rupee",
        decimal_places: 2
      )

      expect(currency).not_to be_valid
    end

    it "requires a three-letter uppercase code" do
      currency = described_class.new(
        code: "inr",
        name: "Indian Rupee",
        decimal_places: 2
      )

      expect(currency).not_to be_valid
    end

    it "requires a name" do
      currency = described_class.new(
        code: "INR",
        decimal_places: 2
      )

      expect(currency).not_to be_valid
    end

    it "requires decimal places" do
      currency = described_class.new(
        code: "INR",
        name: "Indian Rupee"
      )

      expect(currency).not_to be_valid
    end

    it "accepts zero decimal places" do
      currency = described_class.new(
        code: "JPY",
        name: "Japanese Yen",
        decimal_places: 0
      )

      expect(currency).to be_valid
    end

    it "accepts three decimal places" do
      currency = described_class.new(
        code: "BHD",
        name: "Bahraini Dinar",
        decimal_places: 3
      )

      expect(currency).to be_valid
    end

    it "rejects negative decimal places" do
      currency = described_class.new(
        code: "INR",
        name: "Indian Rupee",
        decimal_places: -1
      )

      expect(currency).not_to be_valid
    end

    it "rejects decimal places greater than four" do
      currency = described_class.new(
        code: "INR",
        name: "Indian Rupee",
        decimal_places: 5
      )

      expect(currency).not_to be_valid
    end
  end

  describe "primary key" do
    it "uses code as its primary key" do
      expect(described_class.primary_key).to eq("code")
    end
  end
end
