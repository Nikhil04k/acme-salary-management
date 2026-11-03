module AuditLogging
  class CreateService
    def initialize(user:, auditable:, action:, audited_changes:)
      @user = user
      @auditable = auditable
      @action = action
      @audited_changes = audited_changes
    end

    def call
      AuditLog.create!(
        user: @user,
        auditable: @auditable,
        action: @action,
        audited_changes: @audited_changes,
        created_at: Time.current
      )
    end
  end
end
