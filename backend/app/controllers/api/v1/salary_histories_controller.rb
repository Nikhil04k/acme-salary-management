module Api
  module V1
    class SalaryHistoriesController < BaseController
      before_action :set_employee
      before_action :set_salary_history, only: %i[show update cancel]

      def index
        authorize SalaryHistory

        salary_histories = @employee.salary_histories
                                    .where(cancelled_at: nil)
                                    .includes(:currency)
                                    .order(effective_from: :desc)

        render json: {
          success: true,
          data: salary_histories.map do |salary_history|
            SalaryHistorySerializer.new(salary_history).as_json
          end
        }, status: :ok
      end

      def show
        authorize @salary_history

        render json: {
          success: true,
          data: SalaryHistorySerializer.new(@salary_history).as_json
        }, status: :ok
      end

      def create
        authorize SalaryHistory

        salary_history = SalaryHistories::CreateService.new(
          employee: @employee,
          created_by: current_user,
          attributes: salary_history_params
        ).call

        render json: {
          success: true,
          message: "Salary history created successfully",
          data: SalaryHistorySerializer.new(salary_history).as_json
        }, status: :created
      rescue SalaryHistories::CreateService::Error => e
        render json: {
          success: false,
          error: e.message
        }, status: :unprocessable_entity
      end

      def update
        authorize @salary_history

        salary_history = SalaryHistories::UpdateService.new(
          salary_history: @salary_history,
          updated_by: current_user,
          attributes: salary_history_params
        ).call

        render json: {
          success: true,
          message: "Salary history updated successfully",
          data: SalaryHistorySerializer.new(salary_history).as_json
        }, status: :ok
      rescue SalaryHistories::UpdateService::Error => e
        render json: {
          success: false,
          error: e.message
        }, status: :unprocessable_entity
      end

      def cancel
        authorize @salary_history

        salary_history = SalaryHistories::CancelService.new(
          salary_history: @salary_history,
          cancelled_by: current_user
        ).call

        render json: {
          success: true,
          message: "Salary history cancelled successfully",
          data: SalaryHistorySerializer.new(salary_history).as_json
        }, status: :ok
      rescue SalaryHistories::CancelService::Error => e
        render json: {
          success: false,
          error: e.message
        }, status: :unprocessable_entity
      end

      private

      def set_employee
        @employee = Employee.find(params[:employee_id])
      end

      def set_salary_history
        @salary_history = @employee.salary_histories.includes(:currency).find(params[:id])
      end

      def salary_history_params
        params.fetch(:salary_history, ActionController::Parameters.new).permit(
          :annual_base_salary,
          :annual_bonus,
          :annual_allowances,
          :currency_code,
          :change_reason,
          :effective_from,
          :effective_to,
          :employee_id,
          :created_by_id,
          :cancelled_at,
          :cancelled_by_id
        )
      end
    end
  end
end
