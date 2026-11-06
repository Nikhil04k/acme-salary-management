
require "set"

# ==================================================
# Countries
# ==================================================

countries_data = [
  { name: "India", iso_code: "IN" },
  { name: "United States", iso_code: "US" },
  { name: "United Kingdom", iso_code: "GB" },
  { name: "Germany", iso_code: "DE" },
  { name: "Canada", iso_code: "CA" },
  { name: "Australia", iso_code: "AU" },
  { name: "Singapore", iso_code: "SG" },
  { name: "Japan", iso_code: "JP" },
  { name: "United Arab Emirates", iso_code: "AE" },
  { name: "Bahrain", iso_code: "BH" }
]

countries_data.each do |attributes|
  Country.find_or_create_by!(iso_code: attributes[:iso_code]) do |country|
    country.name = attributes[:name]
  end
end

# ==================================================
# Departments
# ==================================================

departments_data = [
  "Engineering",
  "Human Resources",
  "Finance",
  "Marketing",
  "Sales",
  "Operations",
  "Customer Support",
  "Legal",
  "Product",
  "IT"
]

departments_data.each do |name|
  Department.find_or_create_by!(name: name)
end

# ==================================================
# Job Titles
# ==================================================

job_titles_data = [
  "Software Engineer",
  "Senior Software Engineer",
  "Engineering Manager",
  "QA Engineer",
  "DevOps Engineer",
  "Product Manager",
  "Product Designer",
  "Data Analyst",
  "Data Engineer",
  "HR Manager",
  "HR Executive",
  "Finance Manager",
  "Accountant",
  "Marketing Manager",
  "Marketing Executive",
  "Sales Manager",
  "Sales Executive",
  "Operations Manager",
  "Customer Support Specialist",
  "IT Administrator"
]

job_titles_data.each do |name|
  JobTitle.find_or_create_by!(name: name)
end

# ==================================================
# Currencies
# ==================================================

currencies_data = [
  { code: "INR", name: "Indian Rupee", decimal_places: 2 },
  { code: "USD", name: "US Dollar", decimal_places: 2 },
  { code: "GBP", name: "British Pound", decimal_places: 2 },
  { code: "EUR", name: "Euro", decimal_places: 2 },
  { code: "CAD", name: "Canadian Dollar", decimal_places: 2 },
  { code: "AUD", name: "Australian Dollar", decimal_places: 2 },
  { code: "SGD", name: "Singapore Dollar", decimal_places: 2 },
  { code: "JPY", name: "Japanese Yen", decimal_places: 0 },
  { code: "AED", name: "UAE Dirham", decimal_places: 2 },
  { code: "BHD", name: "Bahraini Dinar", decimal_places: 3 }
]

currencies_data.each do |attributes|
  Currency.find_or_create_by!(code: attributes[:code]) do |currency|
    currency.name = attributes[:name]
    currency.decimal_places = attributes[:decimal_places]
  end
end

puts "Reference data seeded successfully!"

# ==================================================
# Validate Required Data
# ==================================================

countries = Country.order(:iso_code).to_a
departments = Department.order(:name).to_a
job_titles = JobTitle.order(:name).to_a
currencies_by_code = Currency.all.index_by(&:code)

raise "Countries are missing" if countries.empty?
raise "Departments are missing" if departments.empty?
raise "Job titles are missing" if job_titles.empty?

required_currencies = %w[INR USD GBP EUR CAD AUD SGD JPY AED BHD]
missing_currencies = required_currencies - currencies_by_code.keys

if missing_currencies.any?
  raise "Missing currencies: #{missing_currencies.join(', ')}"
end

hr_user = User.find_by!(role: "hr_manager")

puts "Precondition checks passed."

# ==================================================
# Employees - Generate 10,000 Employees
# ==================================================

puts "Seeding employees..."

first_names = %w[
  Rahul Amit Priya Neha Ankit Sneha
  Arjun Riya Vikram Pooja Karan Ananya
  John Michael Sarah Emma David Olivia
  James Sophia Daniel Emily Robert
  Liam Noah Isabella Lucas
]

last_names = %w[
  Sharma Verma Gupta Singh Patel Kumar
  Mehta Shah Joshi Agarwal
  Smith Johnson Brown Williams Jones
  Miller Davis Wilson Taylor Anderson
]

random = Random.new(20261103)

existing_employee_numbers = Employee.pluck(:employee_number).to_set

employee_rows = []

hire_start_date = Date.new(2015, 1, 1)
hire_end_date = Date.new(2025, 12, 31)

hire_days = (hire_end_date - hire_start_date).to_i

(1..10_000).each do |number|
  employee_number = format("ACME%05d", number)

  next if existing_employee_numbers.include?(employee_number)

  hired_on = hire_start_date + random.rand(hire_days + 1)

  status_roll = random.rand(1..100)

  employment_status =
    case status_roll
    when 1..85
      "active"
    when 86..93
      "inactive"
    else
      "terminated"
    end

  terminated_on = nil

  if employment_status == "terminated"
    available_days = (Date.current - hired_on).to_i

    terminated_on = hired_on +
      random.rand(30..[available_days, 730].min)
  end

  first_name = first_names[random.rand(first_names.length)]
  last_name = last_names[random.rand(last_names.length)]

  employee_rows << {
    employee_number: employee_number,
    first_name: first_name,
    last_name: last_name,
    email: "employee#{format('%05d', number)}@acme.com",
    country_id: countries[random.rand(countries.length)].id,
    department_id: departments[random.rand(departments.length)].id,
    job_title_id: job_titles[random.rand(job_titles.length)].id,
    employment_status: employment_status,
    hired_on: hired_on,
    terminated_on: terminated_on,
    created_at: Time.current,
    updated_at: Time.current
  }
end

employee_rows.each_slice(1_000) do |batch|
  Employee.insert_all!(batch)
  puts "Inserted employee batch. Total so far: #{Employee.count}"
end

puts "Employee seeding completed."
puts "Total employees: #{Employee.count}"

# ==================================================
# Salary Histories - Generate Initial Salary Records
# ==================================================

puts "Seeding initial salary histories..."

salary_config = {
  "IN" => { currency: "INR", min: 300_000, max: 3_000_000 },
  "US" => { currency: "USD", min: 50_000, max: 250_000 },
  "GB" => { currency: "GBP", min: 35_000, max: 150_000 },
  "DE" => { currency: "EUR", min: 35_000, max: 140_000 },
  "CA" => { currency: "CAD", min: 50_000, max: 180_000 },
  "AU" => { currency: "AUD", min: 55_000, max: 190_000 },
  "SG" => { currency: "SGD", min: 45_000, max: 180_000 },
  "JP" => { currency: "JPY", min: 4_000_000, max: 20_000_000 },
  "AE" => { currency: "AED", min: 120_000, max: 600_000 },
  "BH" => { currency: "BHD", min: 12_000, max: 60_000 }
}

existing_employee_ids = SalaryHistory.pluck(:employee_id).to_set

random = Random.new(20261104)

salary_rows = []

Employee.includes(:country).order(:id).find_each do |employee|
  next if existing_employee_ids.include?(employee.id)

  config = salary_config.fetch(employee.country.iso_code)
  currency = currencies_by_code.fetch(config[:currency])

  decimal_places = currency.decimal_places

  base_salary = random.rand(config[:min]..config[:max])

  bonus_percentage = random.rand(0..20)
  allowance_percentage = random.rand(0..10)

  annual_bonus = (
    BigDecimal(base_salary.to_s) * bonus_percentage / 100
  ).round(decimal_places)

  annual_allowances = (
    BigDecimal(base_salary.to_s) * allowance_percentage / 100
  ).round(decimal_places)

  salary_rows << {
    employee_id: employee.id,
    created_by_id: hr_user.id,
    annual_base_salary: base_salary,
    annual_bonus: annual_bonus,
    annual_allowances: annual_allowances,
    currency_code: currency.code,
    effective_from: employee.hired_on,
    effective_to: nil,
    change_reason: "Initial salary record",
    created_at: Time.current,
    updated_at: Time.current
  }
end

salary_rows.each_slice(1_000) do |batch|
  SalaryHistory.insert_all!(batch)
  puts "Inserted salary batch. Total so far: #{SalaryHistory.count}"
end

puts "Salary history seeding completed."
puts "Total salary histories: #{SalaryHistory.count}"

# ==================================================
# Final Summary
# ==================================================

puts "\n========== SEED SUMMARY =========="

puts "Users: #{User.count}"
puts "Countries: #{Country.count}"
puts "Departments: #{Department.count}"
puts "Job Titles: #{JobTitle.count}"
puts "Currencies: #{Currency.count}"
puts "Employees: #{Employee.count}"
puts "Salary Histories: #{SalaryHistory.count}"

puts "=================================="
puts "Database seeding completed successfully!"
