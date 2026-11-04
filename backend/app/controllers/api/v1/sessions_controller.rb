module Api
  module V1
    class SessionsController < Api::BaseController
      skip_before_action :authenticate_user!, only: [:create]

      def create
        request.env["devise.allow_params_authentication"] = true

        user = request.env["warden"].authenticate(scope: :user)

        if user
          sign_in(:user, user, store: false)

          render json: {
            success: true,
            message: "Login successful",
            user: {
              id: user.id,
              email: user.email,
              role: user.role
            }
          }, status: :ok
        else
          render json: {
            success: false,
            error: "Invalid email or password"
          }, status: :unauthorized
        end
      end

      def destroy
        sign_out(:user)

        render json: {
          success: true,
          message: "Logout successful"
        }, status: :ok
      end
    end
  end
end
