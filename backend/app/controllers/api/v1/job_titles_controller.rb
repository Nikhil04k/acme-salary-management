module Api
  module V1
    class JobTitlesController < BaseController
      def index
        authorize JobTitle

        job_titles = JobTitle.order(:name)

        render json: {
          success: true,
          data: job_titles.map do |job_title|
            {
              id: job_title.id,
              name: job_title.name
            }
          end
        }, status: :ok
      end
    end
  end
end
