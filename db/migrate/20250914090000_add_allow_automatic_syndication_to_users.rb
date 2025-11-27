class AddAllowAutomaticSyndicationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :allow_automatic_syndication, :boolean, null: false, default: true
    add_index :users, :allow_automatic_syndication
  end
end
