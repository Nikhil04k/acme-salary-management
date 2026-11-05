class EmployeePolicy
  attr_reader :user, :employee

  def initialize(user, employee)
    @user = user
    @employee = employee
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

  def import?
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
