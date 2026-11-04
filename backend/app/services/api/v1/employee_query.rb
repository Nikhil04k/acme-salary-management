module Api
  module V1
    class EmployeeQuery
      def initialize(params)
        @params = params
      end

      def call
        employees = Employee.includes(:country, :department, :job_title)

        employees = apply_search(employees)
        employees = apply_country_filter(employees)
        employees = apply_department_filter(employees)
        employees = apply_job_title_filter(employees)
        employees = apply_status_filter(employees)

        apply_sorting(employees)
      end

      private

      def apply_search(employees)
        search = @params[:search].to_s.strip
        return employees if search.blank?

        search_term = "%#{Employee.sanitize_sql_like(search)}%"

        employees.where(
          "employees.first_name LIKE :term OR " \
          "employees.last_name LIKE :term OR " \
          "employees.employee_number LIKE :term OR " \
          "employees.email LIKE :term",
          term: search_term
        )
      end

      def apply_country_filter(employees)
        return employees if @params[:country_id].blank?

        employees.where(country_id: @params[:country_id])
      end

      def apply_department_filter(employees)
        return employees if @params[:department_id].blank?

        employees.where(department_id: @params[:department_id])
      end

      def apply_job_title_filter(employees)
        return employees if @params[:job_title_id].blank?

        employees.where(job_title_id: @params[:job_title_id])
      end

      def apply_status_filter(employees)
        return employees if @params[:employment_status].blank?

        employees.where(employment_status: @params[:employment_status])
      end

      def apply_sorting(employees)
        allowed_columns = %w[
          employee_number
          first_name
          last_name
          hired_on
          created_at
        ]

        sort_by = @params[:sort_by].presence || "id"
        sort_order = @params[:sort_order].presence || "asc"

        unless allowed_columns.include?(sort_by) || sort_by == "id"
          raise ArgumentError, "Invalid sort_by parameter"
        end

        unless %w[asc desc].include?(sort_order)
          raise ArgumentError, "Invalid sort_order parameter"
        end

        employees.order(sort_by => sort_order)
      end
    end
  end
end
