require "test_helper"

class DeterminesNewestKnownPostTest < ActiveSupport::TestCase
  def test_returns_nil_when_feed_has_no_posts
    feed = New.create(Feed, user: New.create(User), url: "http://example.com/feed.xml", label: "Empty")

    timestamp = DeterminesNewestKnownPost.new.timestamp_for(feed)

    assert_nil timestamp
  end

  def test_prefers_latest_remote_published_at
    feed = New.create(Feed, user: New.create(User), url: "http://example.com/feed.xml", label: "Published")
    older = Time.utc(2025, 1, 1, 10, 0, 0)
    newer = Time.utc(2025, 1, 2, 12, 0, 0)

    New.create(Post, feed: feed, url: "http://example.com/1", remote_id: "1", remote_published_at: older)
    New.create(Post, feed: feed, url: "http://example.com/2", remote_id: "2", remote_published_at: newer)

    timestamp = DeterminesNewestKnownPost.new.timestamp_for(feed)

    assert_equal newer, timestamp
  end

  def test_falls_back_to_remote_updated_at_when_published_missing
    feed = New.create(Feed, user: New.create(User), url: "http://example.com/feed.xml", label: "Updated")
    older = Time.utc(2025, 1, 3, 9, 0, 0)
    newer = Time.utc(2025, 1, 3, 15, 0, 0)

    New.create(Post, feed: feed, url: "http://example.com/1", remote_id: "1", remote_published_at: nil, remote_updated_at: older)
    New.create(Post, feed: feed, url: "http://example.com/2", remote_id: "2", remote_published_at: nil, remote_updated_at: newer)

    timestamp = DeterminesNewestKnownPost.new.timestamp_for(feed)

    assert_equal newer, timestamp
  end

  def test_falls_back_to_created_at_when_no_remote_timestamps
    feed = New.create(Feed, user: New.create(User), url: "http://example.com/feed.xml", label: "Created")

    older = Time.utc(2025, 1, 4, 8, 0, 0)
    newer = Time.utc(2025, 1, 5, 18, 0, 0)

    New.create(Post,
      feed: feed,
      url: "http://example.com/1",
      remote_id: "1",
      remote_published_at: nil,
      remote_updated_at: nil,
      created_at: older,
      updated_at: older)

    New.create(Post,
      feed: feed,
      url: "http://example.com/2",
      remote_id: "2",
      remote_published_at: nil,
      remote_updated_at: nil,
      created_at: newer,
      updated_at: newer)

    timestamp = DeterminesNewestKnownPost.new.timestamp_for(feed)

    assert_equal newer, timestamp
  end
end
