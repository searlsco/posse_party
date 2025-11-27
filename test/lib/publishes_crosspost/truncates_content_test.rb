require "test_helper"

class PublishesCrosspost
  class TruncatesContentTest < ActiveSupport::TestCase
    setup do
      @identifies_pattern_ranges = IdentifiesPatternRanges.new
      @subject = TruncatesContent.new
    end

    # Ended up extraacting the responsibility of pattern range identification but don't want
    # to rewrite the whole test so here we are
    def truncate(str, len, marker: "…")
      url_analysis = @identifies_pattern_ranges.identify(str, Patterns::URL, metadata: {type: :link})
      hashtag_analysis = @identifies_pattern_ranges.identify(str, Patterns::HASHTAG, metadata: {type: :tag})

      pattern_ranges = url_analysis.pattern_ranges + hashtag_analysis.pattern_ranges

      @subject.truncate(str, len, unbreakables: pattern_ranges, counter: Platforms::Bsky::POST_CONSTRAINTS[:counter], marker:)
    end

    def test_basics_counting_grapheme_clusters
      # Regardless of whether there's plenty of length
      assert_equal "Hello", truncate("   Hello  ", 50)

      assert_equal "Hello", truncate("Hello", 5)
      assert_equal "Hello…", truncate("Hello, world!", 6)
      assert_equal "Hello, world!", truncate("Hello, world!", 14)
      assert_equal "Hello, world!", truncate("Hello, world!", 13)
      assert_equal "Hello, worl…", truncate("Hello, world!", 12)
      assert_equal "🧑‍🧑‍🧒‍🧒 acme.co", truncate("🧑‍🧑‍🧒‍🧒 acme.co", 10)
      assert_equal "🧑‍🧑‍🧒‍🧒 acme.co", truncate("🧑‍🧑‍🧒‍🧒 acme.co", 9)
      assert_equal "🧑‍🧑‍🧒‍🧒…", truncate("🧑‍🧑‍🧒‍🧒 acme.co", 8)
      assert_equal "🧑‍🧑‍🧒‍🧒…", truncate("🧑‍🧑‍🧒‍🧒 www.example.com is cool", 8)
      # Room for the URL:
      assert_equal "🧑‍🧑‍🧒‍🧒 https://a.co/foo?bar=true <…", truncate("🧑‍🧑‍🧒‍🧒 https://a.co/foo?bar=true <-- free links!", 30)
      # Don't put a marker right after an unbreakable token (since URLs, hashtags might break if followed by …)
      assert_equal "🧑‍🧑‍🧒‍🧒 https://a.co/foo?bar=true …", truncate("🧑‍🧑‍🧒‍🧒 https://a.co/foo?bar=true <-- free links!", 29)
      # Skip the marker entirely if it would be right after the URL and there's no room for it
      assert_equal "🧑‍🧑‍🧒‍🧒 https://a.co/foo?bar=true", truncate("🧑‍🧑‍🧒‍🧒 https://a.co/foo?bar=true <-- free links!", 28)
      # TODO: failing because we are limiting with space for the marker first, which results in the marker limit impinging on the URL even though it'd fit
      assert_equal "🧑‍🧑‍🧒‍🧒 https://a.co/foo?bar=true", truncate("🧑‍🧑‍🧒‍🧒 https://a.co/foo?bar=true <-- free links!", 27)
      # No room for the url
      assert_equal "🧑‍🧑‍🧒‍🧒…", truncate("🧑‍🧑‍🧒‍🧒 https://a.co/foo?bar=true <-- free links!", 26)
      # Really not enough room for the url
      assert_equal "🧑‍🧑‍🧒‍🧒…", truncate("🧑‍🧑‍🧒‍🧒 https://a.co/foo?bar=true <-- free links!", 4)

      assert_equal "Follow me 🧑‍🧑‍🧒‍🧒 #followfriday …", truncate("Follow me 🧑‍🧑‍🧒‍🧒 #followfriday #peeps", 27)
      assert_equal "Follow me 🧑‍🧑‍🧒‍🧒 #followfriday", truncate("Follow me 🧑‍🧑‍🧒‍🧒 #followfriday #peeps", 26)
      assert_equal "Follow me 🧑‍🧑‍🧒‍🧒 #followfriday", truncate("Follow me 🧑‍🧑‍🧒‍🧒 #followfriday #peeps", 25)
      assert_equal "Follow me 🧑‍🧑‍🧒‍🧒…", truncate("Follow me 🧑‍🧑‍🧒‍🧒 #followfriday #peeps", 24)

      assert_equal "Follow me 🧑‍🧑‍🧒‍🧒 justin.searls.co #followfriday", truncate("Follow me 🧑‍🧑‍🧒‍🧒 justin.searls.co #followfriday", 42)
      assert_equal "Follow me 🧑‍🧑‍🧒‍🧒 justin.searls.co …", truncate("Follow me 🧑‍🧑‍🧒‍🧒 justin.searls.co #followfriday", 41)
      assert_equal "Follow me 🧑‍🧑‍🧒‍🧒 justin.searls.co …", truncate("Follow me 🧑‍🧑‍🧒‍🧒 justin.searls.co #followfriday", 30)
      assert_equal "Follow me 🧑‍🧑‍🧒‍🧒 justin.searls.co", truncate("Follow me 🧑‍🧑‍🧒‍🧒 justin.searls.co #followfriday", 29)
      assert_equal "Follow me 🧑‍🧑‍🧒‍🧒 justin.searls.co", truncate("Follow me 🧑‍🧑‍🧒‍🧒 justin.searls.co #followfriday", 28)
      assert_equal "Follow me 🧑‍🧑‍🧒‍🧒…", truncate("Follow me 🧑‍🧑‍🧒‍🧒 justin.searls.co #followfriday", 27)

      # Using a multi-grapheme marker
      assert_equal "I am #thirsty", truncate("I am #thirsty", 14, marker: "🧑‍🧑‍🧒‍🧒")
      assert_equal "I am #thirsty", truncate("I am #thirsty", 13, marker: "🧑‍🧑‍🧒‍🧒")
      assert_equal "I am🧑‍🧑‍🧒‍🧒", truncate("I am #thirsty", 12, marker: "🧑‍🧑‍🧒‍🧒")
      assert_equal "I am🧑‍🧑‍🧒‍🧒", truncate("I am #thirsty", 5, marker: "🧑‍🧑‍🧒‍🧒")
      assert_equal "I a🧑‍🧑‍🧒‍🧒", truncate("I am #thirsty", 4, marker: "🧑‍🧑‍🧒‍🧒")
    end
  end
end
