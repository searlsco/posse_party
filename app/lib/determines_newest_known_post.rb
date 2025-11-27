class DeterminesNewestKnownPost
  def timestamp_for(feed)
    feed.posts.pick(
      Arel.sql("COALESCE(MAX(remote_published_at), MAX(remote_updated_at), MAX(created_at))")
    )
  end
end
