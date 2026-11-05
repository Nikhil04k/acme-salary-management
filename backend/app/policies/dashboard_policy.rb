class DashboardPolicy
  def initialize(user, _record)
    @user = user
  end

  def show?
    User::ROLES.include?(@user.role)
  end
end
