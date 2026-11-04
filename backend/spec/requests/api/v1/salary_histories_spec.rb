
require "rails_helper"

RSpec.describe "API V1 Salary Histories", type: :request do
  let(:user) { create(:user, role: "hr_manager") }
  let(:country) { create(:country, iso_code: "IN") }
  let(:department) { create(:department) }
  let(:job_title) { create(:job_title) }

  let(:employee) do
    create(
      :employee,
      country: country,
      department: department,
      job_title: job_title
    )
  end

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

  describe "GET /api/v1/employees/:employee_id/salary_histories" do
    it "returns salary histories ordered by effective date descending" do
      old_salary = create(
        :salary_history,
        employee: employee,
        effective_from: 2.years.ago.to_date,
        effective_to: 1.year.ago.to_date
      )

      new_salary = create(
        :salary_history,
        employee: employee,
        effective_from: 1.year.ago.to_date
      )

      get "/api/v1/employees/#{employee.id}/salary_histories",
          headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["success"]).to be true
      expect(body["data"].map { |item| item["id"] })
        .to eq([new_salary.id, old_salary.id])
    end

    it "excludes cancelled salary histories" do
      active_salary = create(
        :salary_history,
        employee: employee,
        effective_from: 2.years.ago.to_date,
        effective_to: 1.year.ago.to_date
      )

      cancelled_salary = create(
        :salary_history,
        :cancelled,
        employee: employee,
        effective_from: 1.year.ago.to_date
      )

      get "/api/v1/employees/#{employee.id}/salary_histories",
          headers: headers

      expect(response).to have_http_status(:ok)

      ids = response.parsed_body["data"].map { |item| item["id"] }

      expect(ids).to contain_exactly(active_salary.id)
      expect(ids).not_to include(cancelled_salary.id)
    end

    it "returns an empty array when no salary history exists" do
      get "/api/v1/employees/#{employee.id}/salary_histories",
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to eq([])
    end

    it "rejects unauthenticated requests" do
      get "/api/v1/employees/#{employee.id}/salary_histories",
          headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "allows viewers to access salary histories" do
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

      get "/api/v1/employees/#{employee.id}/salary_histories",
          headers: viewer_headers

      expect(response).to have_http_status(:ok)
    end

    it "returns 404 when employee does not exist" do
      get "/api/v1/employees/999999999/salary_histories",
          headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/employees/:employee_id/salary_histories/:id" do
    let!(:salary) do
      create(
        :salary_history,
        employee: employee,
        effective_from: 1.year.ago.to_date
      )
    end

    it "returns salary history details" do
      get "/api/v1/employees/#{employee.id}/salary_histories/#{salary.id}",
          headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["success"]).to be true
      expect(body["data"]["id"]).to eq(salary.id)
      expect(body["data"]["annual_base_salary"].to_d)
        .to eq(salary.annual_base_salary)
      expect(body["data"]["currency"]["code"]).to eq(salary.currency_code)
    end

    it "does not return a salary belonging to another employee" do
      another_employee = create(
        :employee,
        country: country,
        department: department,
        job_title: job_title
      )

      get "/api/v1/employees/#{another_employee.id}/salary_histories/#{salary.id}",
          headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when salary history does not exist" do
      get "/api/v1/employees/#{employee.id}/salary_histories/999999999",
          headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "allows viewers to access salary details" do
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

      get "/api/v1/employees/#{employee.id}/salary_histories/#{salary.id}",
          headers: viewer_headers

      expect(response).to have_http_status(:ok)
    end
  end
end
