
require "rails_helper"

RSpec.describe "API V1 Salary History Cancellation", type: :request do
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

  let(:previous_salary) do
    create(
      :salary_history,
      employee: employee,
      effective_from: 1.year.ago.to_date,
      effective_to: 6.months.from_now.to_date
    )
  end

  let(:salary) do
    create(
      :salary_history,
      employee: employee,
      effective_from: 6.months.from_now.to_date
    )
  end

  let(:endpoint) do
    "/api/v1/employees/#{employee.id}/salary_histories/#{salary.id}/cancel"
  end

  describe "POST /api/v1/employees/:employee_id/salary_histories/:id/cancel" do
    it "cancels a future scheduled salary" do
      salary

      post endpoint, headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["success"]).to be true
      expect(body["message"]).to eq("Salary history cancelled successfully")

      expect(salary.reload.cancelled_at).to be_present
      expect(salary.cancelled_by).to eq(user)
    end

    it "creates an audit log for cancellation" do
      salary

      expect {
        post endpoint, headers: headers
      }.to change(AuditLog, :count).by(1)

      audit_log = AuditLog.last

      expect(audit_log.user).to eq(user)
      expect(audit_log.auditable).to eq(salary)
      expect(audit_log.action).to eq("cancel")
      expect(audit_log.audited_changes).to include("cancelled_at")
    end

    it "restores the previous salary period" do
      previous_salary
      salary

      post endpoint, headers: headers

      expect(response).to have_http_status(:ok)

      expect(previous_salary.reload.effective_to).to be_nil
    end

    it "creates an audit log for the previous salary adjustment" do
      previous_salary
      salary

      expect {
        post endpoint, headers: headers
      }.to change(AuditLog, :count).by(2)

      previous_salary_audit = AuditLog.find_by!(
        auditable: previous_salary,
        action: "update"
      )

      expect(previous_salary_audit.audited_changes)
        .to include("effective_to")
    end

    it "does not allow cancellation of an already effective salary" do
      current_salary = create(
        :salary_history,
        employee: employee,
        effective_from: Date.current
      )

      post "/api/v1/employees/#{employee.id}/salary_histories/#{current_salary.id}/cancel",
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"])
        .to include("Only future scheduled salaries can be cancelled")

      expect(current_salary.reload.cancelled_at).to be_nil
    end

    it "does not allow viewers to cancel salary histories" do
      salary

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

      post endpoint, headers: viewer_headers

      expect(response).to have_http_status(:forbidden)
      expect(salary.reload.cancelled_at).to be_nil
    end

    it "rejects unauthenticated requests" do
      salary

      post endpoint,
           headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not cancel a salary belonging to another employee" do
      salary

      another_employee = create(
        :employee,
        country: country,
        department: department,
        job_title: job_title
      )

      post "/api/v1/employees/#{another_employee.id}/salary_histories/#{salary.id}/cancel",
           headers: headers

      expect(response).to have_http_status(:not_found)
      expect(salary.reload.cancelled_at).to be_nil
    end
  end
end
