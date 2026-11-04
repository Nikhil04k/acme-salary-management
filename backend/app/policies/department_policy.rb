class DepartmentPolicy
  attr_reader :user, :department

  def initialize(user, department)
    @user = user
    @department = department
  end

  def index?
    %w[admin hr_manager viewer].include?(user.role)
  end
end
