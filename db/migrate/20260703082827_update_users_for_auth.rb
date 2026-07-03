class UpdateUsersForAuth < ActiveRecord::Migration[8.1]
  def change
    remove_index :users, :tmdb_account_id
    remove_column :users, :tmdb_account_id, :integer

    add_column :users, :email,           :string, null: false, default: ""
    add_column :users, :password_digest, :string, null: false, default: ""
    add_column :users, :name,            :string, null: false, default: ""
    add_column :users, :phone_number,    :string

    add_index :users, :email, unique: true

    change_column_default :users, :email,           from: "", to: nil
    change_column_default :users, :password_digest, from: "", to: nil
    change_column_default :users, :name,            from: "", to: nil
  end
end
