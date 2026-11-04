module Api
  module V1
    class EmployeePagination
      class InvalidParameter < StandardError; end

      DEFAULT_PAGE = 1
      DEFAULT_PER_PAGE = 20
      MAX_PER_PAGE = 100

      def initialize(params)
        @params = params
      end

      def page
        positive_integer(:page, DEFAULT_PAGE)
      end

      def per_page
        value = positive_integer(:per_page, DEFAULT_PER_PAGE)
        [value, MAX_PER_PAGE].min
      end

      private

      def positive_integer(key, default)
        value = @params[key]
        return default if value.blank?

        integer = Integer(value, 10)
        raise InvalidParameter, "#{key} must be greater than 0" unless integer.positive?

        integer
      rescue ArgumentError, TypeError
        raise InvalidParameter, "#{key} must be a valid positive integer"
      end
    end
  end
end
