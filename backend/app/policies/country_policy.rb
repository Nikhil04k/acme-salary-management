class CountryPolicy
  attr_reader :user, :country

  def initialize(user, country)
    @user = user
    @country = country
  end

  def index?
    permitted_user?
  end

  private

  def permitted_user?
    %w[admin hr_manager viewer].include?(user.role)
  end
end
