class DropSubscriptions < ActiveRecord::Migration[8.0]
  def change
    drop_table :subscriptions # standard:disable Rails/ReversibleMigration
  end
end
