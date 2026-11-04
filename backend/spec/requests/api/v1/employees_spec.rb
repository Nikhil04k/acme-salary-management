require "rails_helper"

RSpec.describe "API V1 Employees", type: :request do
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

  before do
    create_list(
      :employee,
      25,
      country: country,
      department: department,
      job_title: job_title
    )
  end

  describe "GET /api/v1/employees" do
    it "returns 20 employees by default" do
      get "/api/v1/employees", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].size).to eq(20)
      expect(response.parsed_body.dig("pagination", "current_page")).to eq(1)
      expect(response.parsed_body.dig("pagination", "total_count")).to eq(25)
    end

    it "returns the requested number of employees" do
      get "/api/v1/employees",
          params: { per_page: 10 },
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].size).to eq(10)
      expect(response.parsed_body.dig("pagination", "per_page")).to eq(10)
    end

    it "limits per_page to 100" do
      get "/api/v1/employees",
          params: { per_page: 500 },
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("pagination", "per_page")).to eq(100)
      expect(response.parsed_body["data"].size).to eq(25)
    end

    it "returns the second page" do
      get "/api/v1/employees",
          params: { page: 2, per_page: 10 },
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("pagination", "current_page")).to eq(2)
      expect(response.parsed_body["data"].size).to eq(10)
    end

    it "rejects non-numeric page values" do
      get "/api/v1/employees",
          params: { page: "abc" },
          headers: headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["success"]).to be false
    end

    it "rejects zero page values" do
      get "/api/v1/employees",
          params: { page: 0 },
          headers: headers

      expect(response).to have_http_status(:bad_request)
    end

    it "rejects negative per_page values" do
      get "/api/v1/employees",
          params: { per_page: -5 },
          headers: headers

      expect(response).to have_http_status(:bad_request)
    end

    it "rejects non-numeric per_page values" do
      get "/api/v1/employees",
          params: { per_page: "abc" },
          headers: headers

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "search" do
    let!(:rahul) do
      create(
        :employee,
        first_name: "Rahul",
        last_name: "Sharma",
        employee_number: "SEARCH001",
        email: "rahul.search@example.com",
        country: country,
        department: department,
        job_title: job_title
      )
    end

    let!(:john) do
      create(
        :employee,
        first_name: "John",
        last_name: "Smith",
        employee_number: "SEARCH002",
        email: "john.search@example.com",
        country: country,
        department: department,
        job_title: job_title
      )
    end

    it "searches by first name" do
      get "/api/v1/employees",
          params: { search: "Rahul" },
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["pagination"]["total_count"]).to eq(1)
      expect(response.parsed_body["data"].first["first_name"]).to eq("Rahul")
    end

    it "searches by last name" do
      get "/api/v1/employees",
          params: { search: "Smith" },
          headers: headers

      expect(response.parsed_body["pagination"]["total_count"]).to eq(1)
    end

    it "searches by employee number" do
      get "/api/v1/employees",
          params: { search: "SEARCH001" },
          headers: headers

      expect(response.parsed_body["pagination"]["total_count"]).to eq(1)
    end

    it "searches by email" do
      get "/api/v1/employees",
          params: { search: "rahul.search@example.com" },
          headers: headers

      expect(response.parsed_body["pagination"]["total_count"]).to eq(1)
    end

    it "supports partial matching" do
      get "/api/v1/employees",
          params: { search: "Rah" },
          headers: headers

      expect(response.parsed_body["pagination"]["total_count"]).to eq(1)
    end
  end

  describe "filters" do
    let!(:another_country) do
      create(:country, name: "United States", iso_code: "US")
    end

    let!(:another_department) do
      create(:department, name: "Finance")
    end

    let!(:another_job_title) do
      create(:job_title, name: "Product Manager")
    end

    let!(:filtered_employee) do
      create(
        :employee,
        country: another_country,
        department: another_department,
        job_title: another_job_title,
        employment_status: "terminated"
      )
    end

    it "filters by country" do
      get "/api/v1/employees",
          params: { country_id: another_country.id },
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { |e| e["id"] })
        .to contain_exactly(filtered_employee.id)
    end

    it "filters by department" do
      get "/api/v1/employees",
          params: { department_id: another_department.id },
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { |e| e["id"] })
        .to contain_exactly(filtered_employee.id)
    end

    it "filters by job title" do
      get "/api/v1/employees",
          params: { job_title_id: another_job_title.id },
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { |e| e["id"] })
        .to contain_exactly(filtered_employee.id)
    end

    it "filters by employment status" do
      get "/api/v1/employees",
          params: { employment_status: "terminated" },
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { |e| e["id"] })
        .to contain_exactly(filtered_employee.id)
    end

    it "combines search and multiple filters with pagination" do
      get "/api/v1/employees",
          params: {
            search: filtered_employee.first_name,
            country_id: another_country.id,
            department_id: another_department.id,
            job_title_id: another_job_title.id,
            employment_status: "terminated",
            page: 1,
            per_page: 10
          },
          headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["pagination"]["total_count"]).to eq(1)
      expect(body["pagination"]["per_page"]).to eq(10)
      expect(body["data"].map { |employee| employee["id"] })
        .to contain_exactly(filtered_employee.id)
    end
  end

  describe "sorting" do
    it "sorts employees by first name ascending" do
      get "/api/v1/employees",
          params: { sort_by: "first_name", sort_order: "asc" },
          headers: headers

      expect(response).to have_http_status(:ok)

      names = response.parsed_body["data"].map { |employee| employee["first_name"] }

      expect(names).to eq(names.sort)
    end

    it "sorts employees by first name descending" do
      get "/api/v1/employees",
          params: { sort_by: "first_name", sort_order: "desc" },
          headers: headers

      expect(response).to have_http_status(:ok)

      names = response.parsed_body["data"].map { |employee| employee["first_name"] }

      expect(names).to eq(names.sort.reverse)
    end

    it "rejects an invalid sort column" do
      get "/api/v1/employees",
          params: { sort_by: "password" },
          headers: headers

      expect(response).to have_http_status(:bad_request)
    end

    it "rejects an invalid sort order" do
      get "/api/v1/employees",
          params: { sort_order: "random" },
          headers: headers

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /api/v1/employees/:id" do
    let!(:employee) do
      create(
        :employee,
        country: country,
        department: department,
        job_title: job_title
      )
    end

    it "returns employee details" do
      get "/api/v1/employees/#{employee.id}", headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["success"]).to be true
      expect(body["data"]["employee"]["id"]).to eq(employee.id)
      expect(body["data"]["employee"]["employee_number"]).to eq(employee.employee_number)
      expect(body["data"]["current_salary"]).to be_nil
      expect(body["data"]["salary_history"]).to eq([])
    end

    it "returns 404 when employee does not exist" do
      get "/api/v1/employees/999999999", headers: headers

      expect(response).to have_http_status(:not_found)

      expect(response.parsed_body["error"]).to eq("Employee not found")
    end

    it "returns current salary and salary history" do
      salary = create(
        :salary_history,
        employee: employee,
        effective_from: 1.year.ago.to_date,
        effective_to: nil
      )

      get "/api/v1/employees/#{employee.id}", headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["data"]["current_salary"]["id"]).to eq(salary.id)
      expect(body["data"]["salary_history"].first["id"]).to eq(salary.id)
    end

    it "does not treat a future scheduled salary as current" do
      future_salary = create(
        :salary_history,
        employee: employee,
        effective_from: 1.month.from_now.to_date
      )

      get "/api/v1/employees/#{employee.id}", headers: headers

      body = response.parsed_body

      expect(body["data"]["current_salary"]).to be_nil
      expect(body["data"]["salary_history"].map { |s| s["id"] })
        .to include(future_salary.id)
    end

    it "returns only the currently effective salary" do
      old_salary = create(
        :salary_history,
        employee: employee,
        effective_from: 2.years.ago.to_date,
        effective_to: 1.year.ago.to_date
      )

      current_salary = create(
        :salary_history,
        employee: employee,
        effective_from: 1.year.ago.to_date
      )

      get "/api/v1/employees/#{employee.id}", headers: headers

      body = response.parsed_body

      expect(body["data"]["current_salary"]["id"]).to eq(current_salary.id)
      expect(body["data"]["current_salary"]["id"]).not_to eq(old_salary.id)
    end

    it "selects the new salary when the previous salary ends on its start date" do
      create(
        :salary_history,
        employee: employee,
        effective_from: 1.year.ago.to_date,
        effective_to: Date.current
      )

      new_salary = create(
        :salary_history,
        employee: employee,
        effective_from: Date.current
      )

      get "/api/v1/employees/#{employee.id}", headers: headers

      body = response.parsed_body

      expect(body["data"]["current_salary"]["id"]).to eq(new_salary.id)
    end
  end
end
