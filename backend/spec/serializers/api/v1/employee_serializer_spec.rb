require "rails_helper"

RSpec.describe Api::V1::EmployeeSerializer do
  let(:employee) { create(:employee) }

  subject(:serialized_employee) do
    described_class.new(employee).as_json
  end

  it "returns employee details" do
    expect(serialized_employee).to include(
      id: employee.id,
      employee_number: employee.employee_number,
      first_name: employee.first_name,
      last_name: employee.last_name,
      email: employee.email,
      employment_status: employee.employment_status
    )
  end

  it "returns associated country, department and job title" do
    expect(serialized_employee[:country][:name]).to eq(employee.country.name)
    expect(serialized_employee[:department][:name]).to eq(employee.department.name)
    expect(serialized_employee[:job_title][:name]).to eq(employee.job_title.name)
  end
end
