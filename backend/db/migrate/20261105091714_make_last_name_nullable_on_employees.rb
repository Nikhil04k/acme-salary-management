class MakeLastNameNullableOnEmployees < ActiveRecord::Migration[8.0]
  def change
    change_column_null :employees, :last_name, true
  end
end
