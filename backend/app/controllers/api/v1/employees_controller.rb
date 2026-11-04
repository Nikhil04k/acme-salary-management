module Api
  module V1
    class EmployeesController < BaseController
      def index
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
    end
  end
end
