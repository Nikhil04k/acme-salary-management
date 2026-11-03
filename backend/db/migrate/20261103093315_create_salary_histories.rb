class CreateSalaryHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :salary_histories do |t|
      t.references :employee,
                   null: false,
                   foreign_key: true,
                   index: false

      t.references :created_by,
                   null: false,
                   foreign_key: { to_table: :users }

      t.decimal :annual_base_salary,
                precision: 19,
                scale: 4,
                null: false

      t.decimal :annual_bonus,
                precision: 19,
                scale: 4,
                null: false,
                default: 0

      t.decimal :annual_allowances,
                precision: 19,
                scale: 4,
                null: false,
                default: 0

      t.string :currency_code,
               limit: 3,
               null: false

      t.date :effective_from, null: false
      t.date :effective_to

      t.string :change_reason, limit: 500

      t.timestamps
    end

    # Currency foreign key references currencies.code
    add_foreign_key :salary_histories,
                    :currencies,
                    column: :currency_code,
                    primary_key: :code

    # Query optimization indexes
    add_index :salary_histories,
              [:employee_id, :effective_from],
              name: "index_salary_histories_on_employee_and_effective_from"

    add_index :salary_histories,
              [:currency_code, :effective_from],
              name: "index_salary_histories_on_currency_and_effective_from"

    # Data integrity constraints
    add_check_constraint :salary_histories,
                         "annual_base_salary >= 0 AND annual_bonus >= 0 AND annual_allowances >= 0",
                         name: "check_salary_histories_amounts_non_negative"

    add_check_constraint :salary_histories,
                         "effective_to IS NULL OR effective_to > effective_from",
                         name: "check_salary_histories_effective_dates"
  end
end
