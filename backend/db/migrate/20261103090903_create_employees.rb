class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.string :employee_number, null: false, limit: 20
      t.string :first_name, null: false, limit: 100
      t.string :last_name, null: false, limit: 100
      t.string :email, null: false, limit: 255

      t.references :country, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true
      t.references :job_title, null: false, foreign_key: true

      t.string :employment_status, null: false, default: "active"
      t.date :hired_on, null: false
      t.date :terminated_on

      t.timestamps
    end

    # Unique indexes
    add_index :employees, :employee_number, unique: true
    add_index :employees, :email, unique: true

    # Filtering indexes
    add_index :employees, :employment_status
    add_index :employees, [:country_id, :department_id, :employment_status],
              name: "index_employees_on_country_department_status"
  end
end
