
module Api
  module V1
    class DashboardsController < BaseController
      def overview
        authorize :dashboard, :show?
        render json: {
          success: true,
          data: Dashboard::OverviewQuery.new.call
        }, status: :ok
      end

      def employee_distribution
        authorize :dashboard, :show?
        render json: {
          success: true,
          data: Dashboard::EmployeeDistributionQuery.new.call
        }, status: :ok
      end

      def salary_analytics
        authorize :dashboard, :show?
        render json: {
          success: true,
          data: Dashboard::SalaryAnalyticsQuery.new.call
        }, status: :ok
      end

      def recent_salary_changes
        authorize :dashboard, :show?

        limit = params.fetch(:limit, 10)

        unless limit.to_s.match?(/\A\d+\z/) && limit.to_i.positive?
          return render json: {
            success: false,
            error: "Limit must be a positive integer"
          }, status: :unprocessable_entity
        end

        data = Dashboard::RecentSalaryChangesQuery.new(
          limit: limit.to_i
        ).call

        render json: {
          success: true,
          data: data
        }, status: :ok
      end
    end
  end
end
