class CreateProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.integer :rank, null: false
      t.text :description

      t.timestamps
    end

    add_index :products, :rank, unique: true
  end
end
