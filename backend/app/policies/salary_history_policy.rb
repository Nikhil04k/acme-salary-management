class SalaryHistoryPolicy
  attr_reader :user, :salary_history

  def initialize(user, salary_history)
    @user = user
    @salary_history = salary_history
  end

  def index?
    permitted_user?
  end

  def show?
    permitted_user?
  end

  def create?
    management_user?
  end

  def update?
    management_user?
  end

  def cancel?
    management_user?
  end

  private

  def permitted_user?
    %w[admin hr_manager viewer].include?(user.role)
  end

  def management_user?
    %w[admin hr_manager].include?(user.role)
  end
end
