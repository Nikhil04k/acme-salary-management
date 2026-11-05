module Api
  module V1
    class MeController < BaseController
      def show
        render json: {
          success: true,
          data: {
            id: current_user.id,
            email: current_user.email,
            role: current_user.role
          }
        }, status: :ok
      end
    end
  end
end
