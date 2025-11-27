class AddGinSearchIndexToPosts < ActiveRecord::Migration[7.0]
  def up
    # Enable the pg_trgm extension for trigram matching
    enable_extension "pg_trgm"

    # Also create a GIN index using pg_trgm for better ILIKE performance
    execute <<~SQL
      CREATE INDEX idx_posts_search_trgm
      ON posts USING gin((
        COALESCE(title, '') || ' ' ||
        COALESCE(url, '') || ' ' ||
        COALESCE(content, '')
      ) gin_trgm_ops)
    SQL
  end

  def down
    # Remove the index
    execute "DROP INDEX IF EXISTS idx_posts_search_trgm"
  end
end
