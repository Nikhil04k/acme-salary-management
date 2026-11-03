class CreateCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :countries do |t|
      t.string :name, null: false, limit: 100
      t.string :iso_code, null: false, limit: 2

      t.timestamps
    end

    add_index :countries, :iso_code, unique: true
  end
end
