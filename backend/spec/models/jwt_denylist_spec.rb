require 'rails_helper'

RSpec.describe JwtDenylist, type: :model do
  describe "Devise JWT revocation strategy" do
    it "includes the denylist revocation strategy" do
      expect(
        described_class.included_modules
      ).to include(Devise::JWT::RevocationStrategies::Denylist)
    end
  end
end
