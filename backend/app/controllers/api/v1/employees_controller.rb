module Api
  module V1
    class EmployeesController < BaseController
      def index
        render json: {
          success: true,
          message: "Authentication successful"
        }, status: :ok
      end
    end
  end
end
