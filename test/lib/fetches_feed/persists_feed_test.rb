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

    def test_persists_google_docs_atom_entries
      feed = New.create(Feed)

      PersistsFeed.new.persist(
        feed,
        ParsesFeed.new.parse(<<~XML),
          <feed xmlns="http://www.w3.org/2005/Atom" xmlns:posse="https://posseparty.com/2024/Feed">
            <entry>
              <title>In case you missed it in Homebrew 5.1.0 release notes: we’re doing a…</title>
              <link href="https://docs.google.com/forms/d/e/1FAIpQLSeeNd7T0Zj9zOl8Y2MP1YITPk_qNUIP5knfCqSmOH2oB2O_UQ/viewform" rel="alternate" type="text/html" />
              <link href="https://mikemcquaid.com/thoughts/20260313121433/" rel="related" type="text/html" />
              <published>2026-03-13T12:14:33+00:00</published>
              <updated>2026-03-13T12:14:33+00:00</updated>
              <id>https://docs.google.com/forms/d/e/1FAIpQLSeeNd7T0Zj9zOl8Y2MP1YITPk_qNUIP5knfCqSmOH2oB2O_UQ/viewform</id>
              <author>
                <name>Mike McQuaid</name>
                <email>mike@mikemcquaid.com</email>
              </author>
              <posse:post format="json"><![CDATA[{"title":"Homebrew User Survey"}]]></posse:post>
            </entry>
          </feed>
        XML
        etag_header: nil,
        last_modified_header: nil
      )

      post = feed.posts.sole

      assert_equal ["Homebrew User Survey", "https://mikemcquaid.com/thoughts/20260313121433/"], [post.title, post.related_url]
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
