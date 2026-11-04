class JobTitlePolicy
  attr_reader :user, :job_title

  def initialize(user, job_title)
    @user = user
    @job_title = job_title
  end

  def index?
    %w[admin hr_manager viewer].include?(user.role)
  end
end
