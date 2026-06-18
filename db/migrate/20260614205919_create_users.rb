class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.integer :tmdb_account_id, null: false

      t.timestamps
    end

    add_index :users, :tmdb_account_id, unique: true
  end
end
