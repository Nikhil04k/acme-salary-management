class CurrencyPolicy
  attr_reader :user, :currency

  def initialize(user, currency)
    @user = user
    @currency = currency
  end

  def index?
    %w[admin hr_manager viewer].include?(user.role)
  end
end
