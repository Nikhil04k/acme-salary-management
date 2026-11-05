
require "rails_helper"

RSpec.describe "API V1 Employee Export", type: :request do
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

  describe "GET /api/v1/employees/export" do
    it "exports employees as CSV" do
      employee = create(:employee)
      token = authenticate(hr_manager)

      get "/api/v1/employees/export",
          headers: { "Authorization" => token }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to include("attachment")

      csv = CSV.parse(response.body, headers: true)

      expect(csv.headers).to include(
        "Employee Number",
        "First Name",
        "Last Name",
        "Email",
        "Country",
        "Department",
        "Job Title"
      )

      expect(csv.map { |row| row["Employee Number"] })
        .to include(employee.employee_number)
    end

    it "supports employee filters" do
      employee = create(:employee)
      create(:employee)

      token = authenticate(hr_manager)

      get "/api/v1/employees/export",
          params: { country_id: employee.country_id },
          headers: { "Authorization" => token }

      expect(response).to have_http_status(:ok)

      csv = CSV.parse(response.body, headers: true)

      expect(csv.map { |row| row["Employee Number"] })
        .to include(employee.employee_number)
    end

    it "allows viewers to export employees" do
      token = authenticate(viewer)

      get "/api/v1/employees/export",
          headers: { "Authorization" => token }

      expect(response).to have_http_status(:ok)
    end

    it "rejects unauthenticated requests" do
      get "/api/v1/employees/export"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
