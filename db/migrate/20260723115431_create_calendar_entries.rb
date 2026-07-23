class CreateCalendarEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_entries do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.integer :tmdb_movie_id, null: false
      t.date :scheduled_on, null: false
      t.string :title, null: false
      t.string :poster_path
      t.decimal :vote_average, precision: 3, scale: 1
      t.string :release_date
      t.boolean :watched, null: false, default: false

      t.timestamps
    end

    add_index :calendar_entries, [ :user_id, :scheduled_on ]
    add_index :calendar_entries, [ :user_id, :tmdb_movie_id, :scheduled_on ], unique: true, name: "index_calendar_entries_uniqueness"
  end
end
