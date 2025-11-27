require "test_helper"

class FetchesFeedTest < ActiveSupport::TestCase
  setup do
    @gets_http_url = Mocktail.of_next(FetchesFeed::GetsHttpUrl)
    @parses_feed = Mocktail.of_next(FetchesFeed::ParsesFeed)
    @persists_feed = Mocktail.of_next(FetchesFeed::PersistsFeed)
    @asks_if_anything_changed = Mocktail.of_next(FetchesFeed::AsksIfAnythingChanged)
    @creates_crossposts = Mocktail.of_next(FetchesFeed::CreatesCrossposts)
    @determines_newest_known_post = Mocktail.of_next(DeterminesNewestKnownPost)

    @subject = FetchesFeed.new

    @feed = New.create(Feed,
      user: New.create(User),
      url: "http://example.com/feed.xml",
      last_checked_at: 30.minutes.ago)
  end

  def test_fetch_no_caching_and_posts_were_persisted
    Now.override!(Time.utc(2025, 1, 1, 12, 0, 0), freeze: true)
    previous_last_checked_at = @feed.last_checked_at
    skip_posts_older_than = Time.utc(2024, 12, 31, 23, 0, 0)
    stubs { @gets_http_url.get(@feed.url, headers: {}) }.with { FetchesFeed::GetsHttpUrl::Response.new(200, {}, "an body") }
    stubs { @parses_feed.parse("an body") }.with { "an parsed feed" }
    stubs {
      @asks_if_anything_changed.ask(@feed.posts) { |blk|
        blk.call
        true
      }
    }.with { true }
    stubs { @determines_newest_known_post.timestamp_for(@feed) }.with { skip_posts_older_than }

    @subject.fetch!(@feed)

    verify { @persists_feed.persist(@feed, "an parsed feed", etag_header: nil, last_modified_header: nil) }
    verify { @creates_crossposts.create!(@feed, published_after: previous_last_checked_at, skip_posts_older_than: skip_posts_older_than) }
  end

  def test_fetching_for_the_first_time_ever
    @feed.last_checked_at = nil
    Now.override!(Time.utc(2025, 1, 1, 12, 0, 0), freeze: true)
    stubs { @gets_http_url.get(@feed.url, headers: {}) }.with { FetchesFeed::GetsHttpUrl::Response.new(200, {}, "an body") }
    stubs { @parses_feed.parse("an body") }.with { "an parsed feed" }
    stubs {
      @asks_if_anything_changed.ask(@feed.posts) { |blk|
        blk.call
        true
      }
    }.with { true }
    stubs { @determines_newest_known_post.timestamp_for(@feed) }.with { nil }

    @subject.fetch!(@feed)

    verify { @persists_feed.persist(@feed, "an parsed feed", etag_header: nil, last_modified_header: nil) }
    verify { @creates_crossposts.create!(@feed, published_after: nil, skip_posts_older_than: nil) } # <-- there_it_is.gif
  end

  def test_fetch_no_caching_and_posts_were_NOT_persisted
    stubs { @gets_http_url.get(@feed.url, headers: {}) }.with { FetchesFeed::GetsHttpUrl::Response.new(200, {}, "an body") }
    stubs { @parses_feed.parse("an body") }.with { "an parsed feed" }
    stubs {
      @asks_if_anything_changed.ask(@feed.posts) { |blk|
        blk.call
        true
      }
    }.with { false }
    stubs { @determines_newest_known_post.timestamp_for(@feed) }.with { nil }

    @subject.fetch!(@feed)

    verify { @persists_feed.persist(@feed, "an parsed feed", etag_header: nil, last_modified_header: nil) }
    verify_never_called { @creates_crossposts.create! }
  end

  def test_fetch_cache_miss
    @feed.etag_header = "an etag"
    @feed.last_modified_header = "an last modified"
    Now.override!(Time.utc(2025, 1, 1, 12, 0, 0), freeze: true)
    previous_last_checked_at = @feed.last_checked_at
    stubs {
      @gets_http_url.get(@feed.url, headers: {
        "If-None-Match" => "an etag",
        "If-Modified-Since" => "an last modified"
      })
    }.with {
      FetchesFeed::GetsHttpUrl::Response.new(200, {
        "etag" => "newer etag",
        "last-modified" => "laster modified"
      }, "an body")
    }
    stubs { @parses_feed.parse("an body") }.with { "an parsed feed" }
    stubs { @asks_if_anything_changed.ask(@feed.posts) { |blk| blk.call || true } }.with { true }
    stubs { @determines_newest_known_post.timestamp_for(@feed) }.with { nil }

    @subject.fetch!(@feed)

    verify { @persists_feed.persist(@feed, "an parsed feed", etag_header: "newer etag", last_modified_header: "laster modified") }
    verify { @creates_crossposts.create!(@feed, published_after: previous_last_checked_at, skip_posts_older_than: nil) }
  end

  def test_fetch_cache_hit
    @feed.etag_header = "an etag"
    @feed.last_modified_header = "an last modified"
    stubs {
      @gets_http_url.get(@feed.url, headers: {
        "If-None-Match" => "an etag",
        "If-Modified-Since" => "an last modified"
      })
    }.with { FetchesFeed::GetsHttpUrl::Response.new(304, {}, nil) }
    stubs { @asks_if_anything_changed.ask(@feed.posts) { |blk| blk.call || true } }.with { false }

    assert_nil @subject.fetch!(@feed)

    verify_never_called { @persists_feed.persist }
    verify_never_called { @creates_crossposts.create! }
  end
end
