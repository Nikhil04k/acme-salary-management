
require "rails_helper"

RSpec.describe "API V1 Dashboard", type: :request do
  let(:admin) { create(:user, role: "admin") }
  let(:hr_manager) { create(:user, role: "hr_manager") }
  let(:viewer) { create(:user, role: "viewer") }

  def authenticate(user)
    post "/api/v1/login",
         params: {
           user: {
             email: user.email,
             password: "Password@123"
           }
         },
         as: :json

    response.headers["Authorization"]
  end

  describe "GET /api/v1/dashboard/overview" do
    it "returns overview statistics" do
      token = authenticate(admin)

      get "/api/v1/dashboard/overview",
          headers: { "Authorization" => token }

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["success"]).to be(true)
      expect(body["data"]).to include("employees")
      expect(body["data"]).to include("average_compensation_by_currency")
    end
  end

  describe "GET /api/v1/dashboard/employee_distribution" do
    it "returns employee distribution" do
      token = authenticate(hr_manager)

      get "/api/v1/dashboard/employee_distribution",
          headers: { "Authorization" => token }

      expect(response).to have_http_status(:ok)

      data = response.parsed_body["data"]

      expect(data).to include(
        "by_country",
        "by_department",
        "by_job_title",
        "by_status"
      )
    end
  end

  describe "GET /api/v1/dashboard/salary_analytics" do
    it "returns salary analytics" do
      token = authenticate(admin)

      get "/api/v1/dashboard/salary_analytics",
          headers: { "Authorization" => token }

      expect(response).to have_http_status(:ok)

      data = response.parsed_body["data"]

      expect(data).to include("by_currency", "by_department")
    end
  end

  describe "GET /api/v1/dashboard/recent_salary_changes" do
    it "returns recent salary changes" do
      token = authenticate(admin)

      get "/api/v1/dashboard/recent_salary_changes",
          headers: { "Authorization" => token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["success"]).to be(true)
    end

    it "rejects an invalid limit" do
      token = authenticate(admin)

      get "/api/v1/dashboard/recent_salary_changes?limit=abc",
          headers: { "Authorization" => token }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "authorization" do
    it "allows viewers to access the dashboard" do
      token = authenticate(viewer)

      get "/api/v1/dashboard/overview",
          headers: { "Authorization" => token }

      expect(response).to have_http_status(:ok)
    end

    it "rejects unauthenticated requests" do
      get "/api/v1/dashboard/overview"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
