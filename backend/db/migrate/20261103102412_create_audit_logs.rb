class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :user,
                   null: false,
                   foreign_key: true

      t.references :auditable,
                   polymorphic: true,
                   null: false,
                   index: true

      t.string :action,
               null: false,
               limit: 30

      t.json :audited_changes, null: false

      t.datetime :created_at, null: false
    end

    add_index :audit_logs,
              [:user_id, :created_at],
              name: "index_audit_logs_on_user_and_created_at"
  end
end
