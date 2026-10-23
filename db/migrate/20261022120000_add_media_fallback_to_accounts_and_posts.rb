class AddMediaFallbackToAccountsAndPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :media_fallback, :string
    add_column :posts, :media_fallback, :string
  end
end
