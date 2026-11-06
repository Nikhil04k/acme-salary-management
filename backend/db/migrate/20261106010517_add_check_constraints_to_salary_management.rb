class AddCheckConstraintsToSalaryManagement < ActiveRecord::Migration[8.0]
  def up
    add_check_constraint_unless_exists(
      "currencies",
      "check_currencies_decimal_places",
      "decimal_places BETWEEN 0 AND 4"
    )

    add_check_constraint_unless_exists(
      "salary_histories",
      "check_salary_histories_amounts_non_negative",
      "annual_base_salary >= 0 AND annual_bonus >= 0 AND annual_allowances >= 0"
    )

    add_check_constraint_unless_exists(
      "salary_histories",
      "check_salary_histories_effective_dates",
      "effective_to IS NULL OR effective_to > effective_from"
    )
  end

  def down
    remove_check_constraint_if_exists(
      "salary_histories",
      "check_salary_histories_effective_dates"
    )

    remove_check_constraint_if_exists(
      "salary_histories",
      "check_salary_histories_amounts_non_negative"
    )

    remove_check_constraint_if_exists(
      "currencies",
      "check_currencies_decimal_places"
    )
  end

  private

  def check_constraint_exists?(table_name, constraint_name)
    result = connection.select_all(
      "SHOW CREATE TABLE #{connection.quote_table_name(table_name)}"
    )

    create_statement = result.rows.first&.last.to_s

    create_statement.include?(
      "CONSTRAINT `#{constraint_name}`"
    )
  end

  def add_check_constraint_unless_exists(table_name, constraint_name, expression)
    return if check_constraint_exists?(table_name, constraint_name)

    execute <<~SQL
      ALTER TABLE #{connection.quote_table_name(table_name)}
      ADD CONSTRAINT #{connection.quote_column_name(constraint_name)}
      CHECK (#{expression})
    SQL
  end

  def remove_check_constraint_if_exists(table_name, constraint_name)
    return unless check_constraint_exists?(table_name, constraint_name)

    execute <<~SQL
      ALTER TABLE #{connection.quote_table_name(table_name)}
      DROP CHECK #{connection.quote_column_name(constraint_name)}
    SQL
  end
end
