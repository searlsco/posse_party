class AddDisabledFeedIdsToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :disabled_feed_ids, :integer, array: true, default: [], null: false
  end
end
