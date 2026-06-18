class CreateLists < ActiveRecord::Migration[8.1]
  def change
    create_table :lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :is_favourite, null: false, default: false

      t.timestamps
    end

    add_index :lists, :user_id, where: "is_favourite = true", unique: true, name: "index_lists_on_user_id_favourite"
  end
end
