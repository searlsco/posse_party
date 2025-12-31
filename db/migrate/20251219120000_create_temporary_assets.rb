class CreateTemporaryAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :temporary_assets do |t|
      t.references :crosspost, null: false, foreign_key: {on_delete: :cascade}, index: {unique: true}
      t.string :key, null: false
      t.binary :bytes, null: false
      t.string :content_type, null: false
      t.timestamps
    end

    add_index :temporary_assets, :key, unique: true
  end
end
