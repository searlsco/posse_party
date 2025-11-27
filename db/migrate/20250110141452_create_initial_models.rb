class CreateInitialModels < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false

      t.timestamps
      t.index :email, unique: true
    end

    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: {on_delete: :cascade}
      t.boolean :active, null: false, default: false

      t.timestamps
    end

    create_table :accounts do |t|
      t.references :user, null: false, foreign_key: {on_delete: :cascade}

      t.string :platform_tag, null: false

      # Account-level settings
      t.boolean :active, null: false, default: true
      t.string :label, null: false
      t.jsonb :credentials, null: false, default: {}

      # Account-level overrides
      t.string :format_string, null: true
      t.boolean :truncate, null: false, default: true
      t.boolean :append_url, null: true
      t.boolean :append_url_if_truncated, null: true
      t.string :append_url_spacer, null: true
      t.string :append_url_label, null: true
      t.boolean :attach_og_card, null: true
      t.string :og_image, null: true

      t.timestamps
    end

    create_table :feeds do |t|
      t.references :user, null: false, foreign_key: {on_delete: :cascade}
      t.string :label, null: false
      t.string :url, null: false

      t.datetime :last_checked_at, null: true

      # Caching
      t.string :etag_header, null: true
      t.string :last_modified_header, null: true

      t.timestamps
      t.index [:user_id, :url], unique: true
    end

    create_table :posts do |t|
      t.references :feed, null: false, foreign_key: {on_delete: :cascade}

      ## Metadata managed by the app
      t.datetime :crossposts_created_at, null: true

      ## Determined by the feed and read-only in the app
      # Atom feed entry fields
      t.string :url, null: false
      t.string :remote_id, null: false
      t.datetime :remote_updated_at, null: true
      t.datetime :remote_published_at, null: true
      t.string :alternate_url, null: true
      t.string :related_url, null: true
      t.string :short_url, null: true
      t.string :author_name, null: true
      t.string :author_email, null: true
      t.string :title, null: true
      t.string :subtitle, null: true
      t.text :summary, null: true
      t.text :content, null: true
      # Post-level overrides
      t.boolean :syndicate, null: true
      t.string :format_string, null: true
      t.boolean :truncate, null: true
      t.boolean :append_url, null: true
      t.boolean :append_url_if_truncated, null: true
      t.string :append_url_spacer, null: true
      t.string :append_url_label, null: true
      t.boolean :attach_og_card, null: true
      t.string :og_image, null: true
      t.string :og_title, null: true
      t.string :og_description, null: true
      # Platform-level overrides
      # mirrors post-level overrides, but for each platform tag in an object (e.g. {bsky: {syndicate: false}})
      t.jsonb :platform_overrides, null: false, default: {}

      t.timestamps
      t.index [:feed_id, :remote_id], unique: true
    end

    create_table :crossposts do |t|
      t.references :post, null: false, foreign_key: {on_delete: :cascade}
      t.references :account, null: false, foreign_key: {on_delete: :cascade}

      t.string :status, null: false # ready, wip, skipped, failed

      # This is a record of the content actually posted
      t.text :content, null: true
      # ID of the created post on the platform
      t.string :remote_id, null: true
      # URL of the created post on the platform
      t.string :url, null: true

      t.integer :attempts, null: false, default: 0
      t.jsonb :failures, default: []
      t.datetime :last_attempted_at, null: true
      t.datetime :published_at, null: true

      t.timestamps
      t.index [:post_id, :account_id], unique: true
    end
  end
end
