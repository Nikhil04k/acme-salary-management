
require "rails_helper"
require "tempfile"

RSpec.describe "API V1 Employee Import", type: :request do
  let(:user) { create(:user, role: "hr_manager") }
  let!(:country) { create(:country, iso_code: "IN") }
  let!(:department) { create(:department) }
  let!(:job_title) { create(:job_title) }

  let(:token) do
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

  let(:headers) do
    {
      "Authorization" => token,
      "Accept" => "application/json"
    }
  end

  let(:csv_headers) do
    %w[
      employee_number
      first_name
      last_name
      email
      country_code
      department
      job_title
      employment_status
      hired_on
      terminated_on
    ].join(",")
  end

  def post_import(csv_content, request_headers: headers)
    Tempfile.create(["employees", ".csv"]) do |file|
      file.write(csv_content)
      file.rewind

      uploaded_file = Rack::Test::UploadedFile.new(
        file.path,
        "text/csv"
      )

      post "/api/v1/employees/import",
           params: { file: uploaded_file },
           headers: request_headers
    end
  end

  describe "POST /api/v1/employees/import" do
    let(:valid_row) do
      [
        "IMPORT001",
        "Rahul",
        "Sharma",
        "rahul.import@example.com",
        "IN",
        department.name,
        job_title.name,
        "active",
        Date.current.to_s,
        ""
      ].join(",")
    end

    it "imports valid employees successfully" do
      expect {
        post_import("#{csv_headers}\n#{valid_row}")
      }.to change(Employee, :count).by(1)

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["success"]).to be true
      expect(body.dig("data", "imported_count")).to eq(1)
      expect(body.dig("data", "failed_count")).to eq(0)

      expect(
        Employee.find_by(employee_number: "IMPORT001")
      ).to be_present
    end

    it "returns an error when the CSV file is missing" do
      post "/api/v1/employees/import", headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to eq("CSV file is required")
    end

    it "rejects invalid CSV headers" do
      expect {
        post_import("employee_number,first_name,email\nIMPORT002,Rahul,rahul@example.com")
      }.not_to change(Employee, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["success"]).to be false
      expect(response.parsed_body["error"]).to include("Invalid CSV headers")
    end

    it "imports valid rows and reports invalid rows" do
      invalid_row = [
        "IMPORT004",
        "John",
        "Doe",
        "john.import@example.com",
        "XX",
        department.name,
        job_title.name,
        "active",
        Date.current.to_s,
        ""
      ].join(",")

      csv_content = [
        csv_headers,
        valid_row,
        invalid_row
      ].join("\n")

      expect {
        post_import(csv_content)
      }.to change(Employee, :count).by(1)

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body.dig("data", "imported_count")).to eq(1)
      expect(body.dig("data", "failed_count")).to eq(1)
      expect(body.dig("data", "errors").first["errors"])
        .to include("Country not found")
    end

    it "prevents viewers from importing employees" do
      viewer = create(:user, role: "viewer")

      post "/api/v1/login",
           params: {
             user: {
               email: viewer.email,
               password: viewer.password
             }
           },
           as: :json

      viewer_headers = {
        "Authorization" => response.headers["Authorization"],
        "Accept" => "application/json"
      }

      expect {
        post_import(
          "#{csv_headers}\n#{valid_row}",
          request_headers: viewer_headers
        )
      }.not_to change(Employee, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects unauthenticated requests" do
      expect {
        post_import(
          "#{csv_headers}\n#{valid_row}",
          request_headers: { "Accept" => "application/json" }
        )
      }.not_to change(Employee, :count)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
