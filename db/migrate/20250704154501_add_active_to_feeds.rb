class AddActiveToFeeds < ActiveRecord::Migration[8.0]
  def change
    add_column :feeds, :active, :boolean, default: true, null: false
  end
end
