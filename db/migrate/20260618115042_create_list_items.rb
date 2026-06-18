class CreateListItems < ActiveRecord::Migration[8.1]
  def change
    create_table :list_items do |t|
      t.references :list, null: false, foreign_key: true
      t.integer :tmdb_movie_id, null: false

      t.timestamps
    end

    add_index :list_items, [:list_id, :tmdb_movie_id], unique: true
  end
end
