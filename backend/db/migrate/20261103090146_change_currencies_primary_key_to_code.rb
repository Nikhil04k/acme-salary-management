class ChangeCurrenciesPrimaryKeyToCode < ActiveRecord::Migration[8.0]
  def up
    record_count = select_value("SELECT COUNT(*) FROM currencies").to_i

    if record_count.positive?
      raise "Cannot change currencies primary key: table contains existing records."
    end

    # Support databases where the code column does not exist yet.
    unless column_exists?(:currencies, :code)
      add_column :currencies, :code, :string, limit: 3, null: false
    end

    # Remove the existing auto-increment integer primary key.
    if column_exists?(:currencies, :id)
      execute "ALTER TABLE currencies MODIFY id BIGINT NOT NULL"
      execute "ALTER TABLE currencies DROP PRIMARY KEY"

      remove_column :currencies, :id
    end

    # Make currency code the primary key.
    unless connection.primary_key(:currencies) == "code"
      execute "ALTER TABLE currencies ADD PRIMARY KEY (code)"
    end
  end

  def down
    execute "ALTER TABLE currencies DROP PRIMARY KEY"

    remove_column :currencies, :code

    execute <<~SQL
      ALTER TABLE currencies
      ADD COLUMN id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST
    SQL
  end
end
