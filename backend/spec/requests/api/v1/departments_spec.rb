require "rails_helper"

RSpec.describe "API V1 Departments", type: :request do
  let(:user) { create(:user, role: "hr_manager") }

  def login_and_get_headers(user)
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

  describe "GET /api/v1/departments" do
    it "returns departments ordered by name" do
      create(:department, name: "Sales")
      create(:department, name: "Engineering")

      get "/api/v1/departments",
          headers: login_and_get_headers(user)

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["success"]).to be true
      expect(body["data"].map { |item| item["name"] })
        .to eq(Department.order(:name).pluck(:name))
    end

    it "returns department id and name" do
      department = create(:department, name: "Research")

      get "/api/v1/departments",
          headers: login_and_get_headers(user)

      result = response.parsed_body["data"]
                     .find { |item| item["id"] == department.id }

      expect(result).to include(
        "id" => department.id,
        "name" => "Research"
      )
    end

    it "rejects unauthenticated requests" do
      get "/api/v1/departments",
          headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "allows viewers to access departments" do
      viewer = create(:user, role: "viewer")

      get "/api/v1/departments",
          headers: login_and_get_headers(viewer)

      expect(response).to have_http_status(:ok)
    end
  end
end
