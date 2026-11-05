module Api
  module V1
    class EmployeesController < BaseController
      def index
        authorize Employee

        pagination = EmployeePagination.new(params)

        employees = EmployeeQuery.new(params).call

        total_count = employees.count

        pagy = Pagy::Offset.new(
          count: total_count,
          page: pagination.page,
          limit: pagination.per_page
        )

        employees = pagy.records(employees)

        render json: {
          success: true,
          data: employees.map do |employee|
            EmployeeSerializer.new(employee).as_json
          end,
          pagination: {
            current_page: pagy.page,
            per_page: pagy.limit,
            total_pages: pagy.pages,
            total_count: pagy.count
          }
        }, status: :ok

      rescue EmployeePagination::InvalidParameter => e
        render json: {
          success: false,
          error: e.message
        }, status: :bad_request
      rescue ArgumentError => e
        render json: {
          success: false,
          error: e.message
        }, status: :bad_request
      end

      def show
        employee = Employee.includes(
          :country,
          :department,
          :job_title,
          salary_histories: :currency
        ).find(params[:id])

        authorize employee

        render json: {
          success: true,
          data: EmployeeDetailsSerializer.new(employee).as_json
        }, status: :ok

      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: "Employee not found"
        }, status: :not_found
      end

      def create
        employee = Employee.new(employee_params)

        authorize employee

        if employee.save
          render json: {
            success: true,
            message: "Employee created successfully",
            data: EmployeeSerializer.new(employee).as_json
          }, status: :created
        else
          render json: {
            success: false,
            errors: employee.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        employee = Employee.find(params[:id])

        authorize employee

        if employee.update(employee_update_params)
          render json: {
            success: true,
            message: "Employee updated successfully",
            data: EmployeeSerializer.new(employee).as_json
          }, status: :ok
        else
          render json: {
            success: false,
            errors: employee.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def export
        authorize Employee, :index?

        employees = EmployeeQuery.new(params).call

        csv = Employees::CsvExportService.new(
          employees: employees
        ).call

        send_data csv,
                  filename: "acme_employees_#{Date.current}.csv",
                  type: "text/csv; charset=utf-8",
                  disposition: "attachment"
      end

      def import
        authorize Employee, :import?

        unless params[:file].present?
          return render json: {
            success: false,
            error: "CSV file is required"
          }, status: :unprocessable_entity
        end

        result = Employees::CsvImportService.new(
          file: params[:file]
        ).call

        render json: {
          success: true,
          message: "Employee import completed",
          data: result
        }, status: :ok

      rescue ArgumentError => e
        render json: {
          success: false,
          error: e.message
        }, status: :unprocessable_entity
      end

      private

        def employee_params
          params.require(:employee).permit(
            :employee_number,
            :first_name,
            :last_name,
            :email,
            :country_id,
            :department_id,
            :job_title_id,
            :employment_status,
            :hired_on,
            :terminated_on
          )
        end

        def employee_update_params
          params.require(:employee).permit(
            :first_name,
            :last_name,
            :email,
            :country_id,
            :department_id,
            :job_title_id,
            :employment_status,
            :hired_on,
            :terminated_on
          )
        end
    end
  end
end
