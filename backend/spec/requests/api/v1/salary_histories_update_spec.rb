
require "rails_helper"

RSpec.describe "API V1 Salary History Updates", type: :request do
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

  let!(:currency) { create(:currency, code: "INR") }

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

  let(:salary) do
    create(
      :salary_history,
      employee: employee,
      effective_from: 1.year.from_now.to_date,
      annual_base_salary: 800000
    )
  end

  let(:endpoint) do
    "/api/v1/employees/#{employee.id}/salary_histories/#{salary.id}"
  end

  let(:valid_params) do
    {
      salary_history: {
        annual_base_salary: 950000,
        annual_bonus: 100000,
        annual_allowances: 50000,
        change_reason: "Annual salary revision"
      }
    }
  end

  describe "PATCH /api/v1/employees/:employee_id/salary_histories/:id" do
    it "updates a future scheduled salary" do
      patch endpoint, params: valid_params, headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["success"]).to be true
      expect(body["data"]["annual_base_salary"].to_d).to eq(950000)
      expect(body["data"]["annual_bonus"].to_d).to eq(100000)
      expect(body["data"]["annual_allowances"].to_d).to eq(50000)

      expect(salary.reload.annual_base_salary).to eq(950000)
    end

    it "creates an audit log for the update" do
      expect {
        patch endpoint, params: valid_params, headers: headers
      }.to change(AuditLog, :count).by(1)

      audit_log = AuditLog.last

      expect(audit_log.user).to eq(user)
      expect(audit_log.auditable).to eq(salary)
      expect(audit_log.action).to eq("update")
      expect(audit_log.audited_changes).to include("annual_base_salary")
    end

    it "does not allow editing an already effective salary" do
      salary.update_column(:effective_from, Date.current)

      patch endpoint, params: valid_params, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"])
        .to include("Only future scheduled salaries can be edited")
    end

    it "rejects changes to immutable attributes" do
      original_date = salary.effective_from

      patch endpoint,
            params: {
              salary_history: {
                effective_from: 2.years.from_now.to_date,
                annual_base_salary: 950000
              }
            },
            headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to include("effective_from")
      expect(salary.reload.effective_from).to eq(original_date)
      expect(salary.annual_base_salary).to eq(800000)
    end

    it "rejects empty update parameters" do
      patch endpoint,
            params: {
              salary_history: {}
            },
            headers: headers,
            as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"])
        .to include("No editable attributes provided")

      expect(salary.reload.annual_base_salary).to eq(800000)
    end

    it "rejects invalid salary amounts" do
      patch endpoint,
            params: {
              salary_history: {
                annual_base_salary: -100
              }
            },
            headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(salary.reload.annual_base_salary).to eq(800000)
    end

    it "does not allow viewers to update salary histories" do
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

      patch endpoint, params: valid_params, headers: viewer_headers

      expect(response).to have_http_status(:forbidden)
      expect(salary.reload.annual_base_salary).to eq(800000)
    end

    it "rejects unauthenticated requests" do
      patch endpoint,
            params: valid_params,
            headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not update a salary belonging to another employee" do
      another_employee = create(
        :employee,
        country: country,
        department: department,
        job_title: job_title
      )

      patch "/api/v1/employees/#{another_employee.id}/salary_histories/#{salary.id}",
            params: valid_params,
            headers: headers

      expect(response).to have_http_status(:not_found)
      expect(salary.reload.annual_base_salary).to eq(800000)
    end
  end
end
