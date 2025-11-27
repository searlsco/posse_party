class FlipAccountAutoToManualCreateCrossposts < ActiveRecord::Migration[8.0]
  def up
    add_column :accounts, :manually_create_crossposts, :boolean, default: false, null: false

    execute <<~SQL
      UPDATE accounts
      SET manually_create_crossposts = NOT COALESCE(automatically_create_crossposts, TRUE)
    SQL

    remove_column :accounts, :automatically_create_crossposts, :boolean
  end

  def down
    add_column :accounts, :automatically_create_crossposts, :boolean, default: true, null: false

    execute <<~SQL
      UPDATE accounts
      SET automatically_create_crossposts = NOT COALESCE(manually_create_crossposts, FALSE)
    SQL

    remove_column :accounts, :manually_create_crossposts, :boolean
  end
end
