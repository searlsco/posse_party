class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :severity, null: false
      t.text :text, null: false
      t.jsonb :refs, null: false, default: [], array: true
      t.boolean :badge, null: false, default: false
      t.datetime :seen_at
      t.virtual :search, type: :tsvector, as: "to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(text,''))", stored: true

      t.timestamps
    end

    add_index :notifications, [:user_id, :created_at], order: {created_at: :desc}, name: :index_notifications_on_user_id_created_at
    add_index :notifications, :refs, using: :gin
    add_index :notifications, :search, using: :gin
  end
end
