class AuditLog < ApplicationRecord
  ACTIONS = %w[create update cancel].freeze

  belongs_to :user

  belongs_to :auditable, polymorphic: true

  validates :action,
            presence: true,
            inclusion: { in: ACTIONS }

  validates :audited_changes, presence: true

  validates :created_at, presence: true

  before_update :prevent_modification
  before_destroy :prevent_deletion

  private

  def prevent_modification
    raise ActiveRecord::ReadOnlyRecord, "Audit logs cannot be modified"
  end

  def prevent_deletion
    raise ActiveRecord::ReadOnlyRecord, "Audit logs cannot be deleted"
  end
end
