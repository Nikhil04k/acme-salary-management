class CreateCurrencies < ActiveRecord::Migration[8.0]
  def change
    create_table :currencies do |t|
      t.string :name, null: false, limit: 100
      t.integer :decimal_places, null: false

      t.timestamps
    end

    add_check_constraint :currencies,
                         "decimal_places BETWEEN 0 AND 4",
                         name: "check_currencies_decimal_places"

    add_index :currencies, :name, unique: true
  end
end
