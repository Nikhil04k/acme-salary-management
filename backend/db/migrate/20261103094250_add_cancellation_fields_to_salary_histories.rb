class AddCancellationFieldsToSalaryHistories < ActiveRecord::Migration[8.0]
  def change
    add_column :salary_histories, :cancelled_at, :datetime
    add_reference :salary_histories,
                  :cancelled_by,
                  foreign_key: { to_table: :users },
                  index: true
  end
end
