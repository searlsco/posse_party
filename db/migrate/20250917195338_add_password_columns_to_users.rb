class AddPasswordColumnsToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :password_digest, :string
    add_column :users, :email_verified_at, :datetime
    add_index :users, :email_verified_at

    now = connection.quote(Time.current)
    execute <<~SQL.squish
      UPDATE users
      SET email_verified_at = #{now}
      WHERE email_verified_at IS NULL
    SQL
  end

  def down
    remove_index :users, :email_verified_at if index_exists?(:users, :email_verified_at)
    remove_column :users, :email_verified_at
    remove_column :users, :password_digest
  end
end
