module Api
  module V1
    class DepartmentsController < BaseController
      def index
        authorize Department

        departments = Department.order(:name)

        render json: {
          success: true,
          data: departments.map do |department|
            {
              id: department.id,
              name: department.name
            }
          end
        }, status: :ok
      end
    end
  end
end
