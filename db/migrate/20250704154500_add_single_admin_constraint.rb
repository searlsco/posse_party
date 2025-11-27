class AddSingleAdminConstraint < ActiveRecord::Migration[8.0]
  def up
    # Create a unique partial index to ensure only one admin exists
    execute <<~SQL
      CREATE UNIQUE INDEX idx_only_one_admin 
      ON users (admin) 
      WHERE admin = true;
    SQL

    # Add a deferrable constraint using an exclusion constraint
    execute <<~SQL
      ALTER TABLE users 
      ADD CONSTRAINT ensure_single_admin
      EXCLUDE (admin WITH =) WHERE (admin = true)
      DEFERRABLE INITIALLY DEFERRED;
    SQL
  end

  def down
    execute "ALTER TABLE users DROP CONSTRAINT IF EXISTS ensure_single_admin;"
    execute "DROP INDEX IF EXISTS idx_only_one_admin;"
  end
end
