module Api
  class BaseController < ActionController::API
    include Pundit::Authorization

    before_action :authenticate_user!

    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from Pundit::NotAuthorizedError, with: :forbidden

    private

    def record_not_found
      render json: {
        success: false,
        error: "Resource not found"
      }, status: :not_found
    end

    def forbidden
      render json: {
        success: false,
        error: "You are not authorized to perform this action"
      }, status: :forbidden
    end
  end
end
