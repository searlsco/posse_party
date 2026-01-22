require "test_helper"

class FetchesFeed
  class PersistsFeedTest < ActiveSupport::TestCase
    def test_raises_when_feed_has_duplicate_ids
      feed = New.create(Feed)
      parsed_feed = ParsesFeed.new.parse(duplicate_id_feed)

      error = assert_raises(StandardError) do
        PersistsFeed.new.persist(feed, parsed_feed, etag_header: nil, last_modified_header: nil)
      end

      assert_equal "Feed contains multiple entries with the same id: https://example.com/interviews/dup", error.message
    end

    def duplicate_id_feed
      <<~XML
        <feed xmlns="http://www.w3.org/2005/Atom">
          <id>https://example.com/interviews.xml</id>
          <title>Interviews</title>
          <entry>
            <id>https://example.com/interviews/dup</id>
            <title>Interview A</title>
            <link href="https://example.com/interviews/dup" rel="alternate" type="text/html" />
            <published>2026-01-16T00:00:00+00:00</published>
            <updated>2026-01-16T00:00:00+00:00</updated>
          </entry>
          <entry>
            <id>https://example.com/interviews/dup</id>
            <title>Interview A (updated)</title>
            <link href="https://example.com/interviews/dup" rel="alternate" type="text/html" />
            <published>2025-10-21T00:00:00+00:00</published>
            <updated>2025-10-21T00:00:00+00:00</updated>
          </entry>
        </feed>
      XML
    end
  end
end
