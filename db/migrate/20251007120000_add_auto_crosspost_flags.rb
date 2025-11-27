class AddAutoCrosspostFlags < ActiveRecord::Migration[7.1]
  def change
    add_column :feeds, :automatically_create_crossposts, :boolean, default: true, null: false
    add_column :accounts, :automatically_create_crossposts, :boolean, default: true, null: false
  end
end
