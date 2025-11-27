require "test_helper"

class FetchesFeed
  class ParsesFeedTest < ActiveSupport::TestCase
    setup do
      @subject = ParsesFeed.new
    end

    def test_supports_my_wacky_feedjira_extensions
      result = @subject.parse(example_feed)

      assert_equal "Some Feed", result.title
      assert_equal "https://example.com/", result.url
      assert_equal "https://example.com/atom.xml", result.feed_url
      assert_equal ["https://example.com/", "https://example.com/atom.xml"], result.links

      entry = result.entries.first
      assert_equal "1", entry.entry_id
      assert_equal "I am a post", entry.title
      assert_equal "text", entry.title_type
      assert_equal "I am a text subtitle", entry.subtitle
      assert_equal "Hello", entry.content
      assert_equal "Person Face", entry.author
      assert_equal "person@example.com", entry.author_email
      assert_equal "https://example.com/post", entry.url
      assert_equal ["https://example.com/post", "https://example.com/other-post"], entry.links
      assert_equal ["alternate", "related"], entry.link_rels
    end

    def test_looks_for_posse_post_if_no_namespace_is_defined
      result = @subject.parse(example_feed(
        entry_elements: <<~XML
          <posse:post format="json"><![CDATA[some json]]></posse:post>
        XML
      ))

      assert_equal "some json", result.entries.first.syndication_config
    end

    def test_looks_for_posse_post_if_namespace_is_set_to_posse
      result = @subject.parse(example_feed(
        feed_attributes: <<~XML,
          xmlns:posse="https://posseparty.com/2024/Feed"
        XML
        entry_elements: <<~XML
          <posse:post format="json"><![CDATA[some json]]></posse:post>
        XML
      ))

      assert_equal "some json", result.entries.first.syndication_config
    end

    def test_does_not_look_for_posse_post_if_a_different_namespace_is_set_for_posse
      result = @subject.parse(example_feed(
        feed_attributes: <<~XML,
          xmlns:posse="https://somebullshit.com/2024/Feed"
        XML
        entry_elements: <<~XML
          <posse:post format="json"><![CDATA[some json]]></posse:post>
        XML
      ))

      assert_nil result.entries.first.syndication_config
    end

    def test_does_look_for_wtf_post_if_a_different_namespace_is_set_for_posse
      result = @subject.parse(example_feed(
        feed_attributes: <<~XML,
          xmlns:posse="https://somebullshit.com/2024/Feed"
          xmlns:wtf="https://posseparty.com/2024/Feed"
        XML
        entry_elements: <<~XML
          <posse:post format="json"><![CDATA[wrong json]]></posse:post>
          <wtf:post format="json"><![CDATA[some json]]></wtf:post>
        XML
      ))

      assert_equal "some json", result.entries.first.syndication_config
    end

    def test_looks_for_wtf_post_if_namespace_is_set_to_wtf
      result = @subject.parse(example_feed(
        feed_attributes: <<~XML,
          xmlns:wtf="https://posseparty.com/2024/Feed"
        XML
        entry_elements: <<~XML
          <wtf:post format="json"><![CDATA[some json]]></wtf:post>
        XML
      ))

      assert_equal "some json", result.entries.first.syndication_config
    end

    def test_does_not_looks_for_posse_post_if_namespace_is_set_to_wtf
      result = @subject.parse(example_feed(
        feed_attributes: <<~XML,
          xmlns:wtf="https://posseparty.com/2024/Feed"
        XML
        entry_elements: <<~XML
          <posse:post format="json"><![CDATA[some json]]></posse:post>
        XML
      ))

      assert_nil result.entries.first.syndication_config
    end

    # UPDATE: I guess Feedjira will just straight up reject atom feeds without the default xmlns set to "http://www.w3.org/2005/Atom"
    # good for them
    #
    # def test_looks_for_toplevel_post_if_namespace_is_set_to_toplevel
    #   result = @subject.parse(example_feed(
    #     feed_attributes: <<~XML,
    #       xmlns="https://posseparty.com/2024/Feed"
    #     XML
    #     entry_elements: <<~XML
    #       <post format="json"><![CDATA[some json]]></post>
    #     XML
    #   ))
    #   assert_equal "some json", result.entries.first.syndication_config
    # end

    def example_feed(feed_attributes: "", entry_elements: "")
      FEED.gsub("@@feed_attributes@@", feed_attributes).gsub("@@entry_elements@@", entry_elements)
    end

    FEED = <<~XML
      <feed
        xml:lang="en-us"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        @@feed_attributes@@
        xmlns="http://www.w3.org/2005/Atom">
        <id>some-feed</id>
        <title>Some Feed</title>
        <link href="https://example.com/" rel="alternate" type="text/html" title="HTML" />
        <link href="https://example.com/atom.xml" rel="self" type="application/atom+xml" title="Atom" />

        <entry>
          <id>1</id>
          <title type="text">I am a post</title>
          <subtitle type="text">I am a text subtitle</subtitle>
          <subtitle type="html">I am an html subtitle</subtitle>
          <link href="https://example.com/post" rel="alternate" type="text/html" />
          <link href="https://example.com/other-post" rel="related" type="text/html" />
          <author>
            <name>Person Face</name>
            <email>person@example.com</email>
          </author>
          <content type="html"><![CDATA[Hello]]></content>
          @@entry_elements@@
        </entry>
      </feed>
    XML
  end
end
