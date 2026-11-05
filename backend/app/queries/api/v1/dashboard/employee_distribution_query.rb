
module Api
  module V1
    module Dashboard
      class EmployeeDistributionQuery
        def call
          {
            by_country: by_country,
            by_department: by_department,
            by_job_title: by_job_title,
            by_status: by_status
          }
        end

        private

        def by_country
          Employee
            .joins(:country)
            .group("countries.id", "countries.name", "countries.iso_code")
            .count
            .map do |(_id, name, iso_code), count|
              {
                country: name,
                iso_code: iso_code,
                employee_count: count
              }
            end
        end

        def by_department
          Employee
            .joins(:department)
            .group("departments.id", "departments.name")
            .count
            .map do |(_id, name), count|
              {
                department: name,
                employee_count: count
              }
            end
        end

        def by_job_title
          Employee
            .joins(:job_title)
            .group("job_titles.id", "job_titles.name")
            .count
            .map do |(_id, name), count|
              {
                job_title: name,
                employee_count: count
              }
            end
        end

        def by_status
          Employee
            .group(:employment_status)
            .count
        end
      end
    end
  end
end
