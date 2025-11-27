class AddMetadataToCrossposts < ActiveRecord::Migration[8.0]
  def change
    add_column :crossposts, :metadata, :jsonb, default: {}, null: false
    add_index :crossposts, :metadata, using: :gin
  end
end
