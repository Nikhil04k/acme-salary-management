require "rails_helper"

RSpec.describe "API V1 Countries", type: :request do
  let(:user) { create(:user, role: "hr_manager") }
  let(:headers) do
    post "/api/v1/login",
         params: {
           user: {
             email: user.email,
             password: user.password
           }
         }

    {
      "Authorization" => response.headers["Authorization"],
      "Accept" => "application/json"
    }
  end

  describe "GET /api/v1/countries" do
    it "returns all countries ordered by name" do
      create(:country, name: "United States", iso_code: "US")
      create(:country, name: "India", iso_code: "IN")

      get "/api/v1/countries", headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["success"]).to be true
      expect(body["data"].map { |country| country["name"] })
        .to eq(Country.order(:name).pluck(:name))
    end

    it "returns country id, name and ISO code" do
      country = create(:country, name: "Japan", iso_code: "JP")

      get "/api/v1/countries", headers: headers

      result = response.parsed_body["data"]
                     .find { |item| item["id"] == country.id }

      expect(result).to include(
        "id" => country.id,
        "name" => "Japan",
        "iso_code" => "JP"
      )
    end

    it "rejects requests without authentication" do
      get "/api/v1/countries", headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "allows viewers to access countries" do
      viewer = create(:user, role: "viewer")

      post "/api/v1/login",
           params: {
             user: {
               email: viewer.email,
               password: viewer.password
             }
           }

      viewer_headers = {
        "Authorization" => response.headers["Authorization"],
        "Accept" => "application/json"
      }

      get "/api/v1/countries", headers: viewer_headers

      expect(response).to have_http_status(:ok)
    end
  end
end
