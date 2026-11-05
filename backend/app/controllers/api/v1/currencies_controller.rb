module Api
  module V1
    class CurrenciesController < BaseController
      def index
        authorize Currency

        currencies = Currency.order(:code)

        render json: {
          success: true,
          data: currencies.map do |currency|
            {
              code: currency.code,
              name: currency.name,
              decimal_places: currency.decimal_places
            }
          end
        }, status: :ok
      end
    end
  end
end
