class RemoveSingleAdminConstraint < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    remove_index :users, name: "idx_only_one_admin", algorithm: :concurrently, if_exists: true
    execute "ALTER TABLE users DROP CONSTRAINT IF EXISTS ensure_single_admin"
  end

  def down
    execute <<~SQL
      CREATE UNIQUE INDEX idx_only_one_admin
      ON users (admin)
      WHERE admin = true
    SQL

    execute <<~SQL
      ALTER TABLE users
      ADD CONSTRAINT ensure_single_admin
      EXCLUDE (admin WITH =) WHERE (admin = true)
      DEFERRABLE INITIALLY DEFERRED
    SQL
  end
end
