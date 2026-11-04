module Api
  module V1
    class CountriesController < BaseController
      def index
        authorize Country

        countries = Country.order(:name)

        render json: {
          success: true,
          data: countries.map do |country|
            {
              id: country.id,
              name: country.name,
              iso_code: country.iso_code
            }
          end
        }, status: :ok
      end
    end
  end
end
