require "rails_helper"

RSpec.describe "API V1 Job Titles", type: :request do
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

  describe "GET /api/v1/job_titles" do
    it "returns job titles ordered by name" do
      create(:job_title, name: "Product Manager")
      create(:job_title, name: "Accountant")

      get "/api/v1/job_titles",
          headers: login_and_get_headers(user)

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["success"]).to be true
      expect(body["data"].map { |item| item["name"] })
        .to eq(JobTitle.order(:name).pluck(:name))
    end

    it "returns job title id and name" do
      job_title = create(:job_title, name: "QA Engineer")

      get "/api/v1/job_titles",
          headers: login_and_get_headers(user)

      result = response.parsed_body["data"]
                     .find { |item| item["id"] == job_title.id }

      expect(result).to include(
        "id" => job_title.id,
        "name" => "QA Engineer"
      )
    end

    it "rejects unauthenticated requests" do
      get "/api/v1/job_titles",
          headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "allows viewers to access job titles" do
      viewer = create(:user, role: "viewer")

      get "/api/v1/job_titles",
          headers: login_and_get_headers(viewer)

      expect(response).to have_http_status(:ok)
    end
  end
end
