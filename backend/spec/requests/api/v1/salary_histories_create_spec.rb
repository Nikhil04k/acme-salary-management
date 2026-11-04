
require "rails_helper"

RSpec.describe "API V1 Salary History Creation", type: :request do
  let(:user) { create(:user, role: "hr_manager") }
  let(:country) { create(:country, iso_code: "IN") }
  let!(:currency) { create(:currency, code: "INR") }
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

  let(:valid_params) do
    {
      salary_history: {
        annual_base_salary: 800000,
        annual_bonus: 100000,
        annual_allowances: 50000,
        currency_code: "INR",
        effective_from: Date.current,
        change_reason: "Annual salary revision"
      }
    }
  end

  let(:endpoint) do
    "/api/v1/employees/#{employee.id}/salary_histories"
  end

  describe "POST /api/v1/employees/:employee_id/salary_histories" do
    it "creates a salary history successfully" do
      expect {
        post endpoint, params: valid_params, headers: headers
      }.to change(SalaryHistory, :count).by(1)

      expect(response).to have_http_status(:created)

      body = response.parsed_body

      expect(body["success"]).to be true
      expect(body["data"]["annual_base_salary"].to_d).to eq(800000)
      expect(body["data"]["currency"]["code"]).to eq("INR")
      expect(body["data"]["effective_from"]).to eq(Date.current.to_s)

      salary = SalaryHistory.last

      expect(salary.employee).to eq(employee)
      expect(salary.created_by).to eq(user)
      expect(salary.effective_to).to be_nil
    end

    it "creates an audit log for the salary creation" do
      expect {
        post endpoint, params: valid_params, headers: headers
      }.to change(AuditLog, :count).by(1)

      audit_log = AuditLog.last

      expect(audit_log.user).to eq(user)
      expect(audit_log.auditable).to eq(SalaryHistory.last)
      expect(audit_log.action).to eq("create")
      expect(audit_log.audited_changes).to include("annual_base_salary")
    end

    it "returns validation errors for invalid salary amounts" do
      invalid_params = valid_params.deep_dup
      invalid_params[:salary_history][:annual_base_salary] = -100

      expect {
        post endpoint, params: invalid_params, headers: headers
      }.not_to change(SalaryHistory, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["success"]).to be false
    end

    it "rejects duplicate effective dates" do
      create(
        :salary_history,
        employee: employee,
        effective_from: Date.current
      )

      expect {
        post endpoint, params: valid_params, headers: headers
      }.not_to change(SalaryHistory, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"])
        .to include("already exists")
    end

    it "rejects unauthenticated requests" do
      post endpoint,
           params: valid_params,
           headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not allow viewers to create salary histories" do
      viewer = create(:user, role: "viewer")

      post "/api/v1/login",
           params: {
             user: {
               email: viewer.email,
               password: "Password@123"
             }
           },
           as: :json

      viewer_headers = {
        "Authorization" => response.headers["Authorization"],
        "Accept" => "application/json"
      }

      expect {
        post endpoint, params: valid_params, headers: viewer_headers
      }.not_to change(SalaryHistory, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 when the employee does not exist" do
      post "/api/v1/employees/999999999/salary_histories",
           params: valid_params,
           headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
