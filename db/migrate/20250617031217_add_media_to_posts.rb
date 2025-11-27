class AddMediaToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :media, :jsonb, array: true, default: [], null: false
    add_index :posts, :media, using: :gin
  end
end
