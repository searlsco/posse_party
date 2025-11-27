require "test_helper"

class PublishesCrosspost
  class IdentifiesPatternRangesTest < ActiveSupport::TestCase
    setup do
      @subject = IdentifiesPatternRanges.new
    end

    def test_basic_api
      result = @subject.identify("a1 b2 c3", /[a-z]/)

      assert_equal "a1 b2 c3", result.string
      assert_equal [
        {
          substring: "a",
          grapheme_index: 0,
          grapheme_length: 1,
          char_index: 0,
          char_length: 1,
          byte_index: 0,
          byte_length: 1
        },
        {
          substring: "b",
          grapheme_index: 3,
          grapheme_length: 1,
          char_index: 3,
          char_length: 1,
          byte_index: 3,
          byte_length: 1
        },
        {
          substring: "c",
          grapheme_index: 6,
          grapheme_length: 1,
          char_index: 6,
          char_length: 1,
          byte_index: 6,
          byte_length: 1
        }
      ], result.pattern_ranges
    end

    def test_urls
      assert_equal [
        {
          substring: "example.com",
          grapheme_index: 20,
          grapheme_length: 11,
          char_index: 20,
          char_length: 11,
          byte_index: 20,
          byte_length: 11
        },
        {
          substring: "http://www.aol.com/hi?name=justin",
          grapheme_index: 36,
          grapheme_length: 33,
          char_index: 36,
          char_length: 33,
          byte_index: 36,
          byte_length: 33
        }
      ], @subject.identify("My favorite site is example.com and http://www.aol.com/hi?name=justin -- how about you?", Patterns::URL).pattern_ranges

      assert_equal [
        {substring: "https://example.com?peeps=true", grapheme_index: 21, grapheme_length: 30, char_index: 21, char_length: 30, byte_index: 21, byte_length: 30}
      ], @subject.identify("I'm just full of for https://example.com?peeps=true <- this is awesome! ", Patterns::URL).pattern_ranges
      assert_equal [
        {substring: "https://example.com?peeps=true", grapheme_index: 23, grapheme_length: 30, char_index: 23, char_length: 30, byte_index: 26, byte_length: 30}
      ], @subject.identify("I'm just full of 💚 for https://example.com?peeps=true <- this is awesome! ", Patterns::URL).pattern_ranges
      assert_equal [
        {substring: "https://example.com?peeps=true", grapheme_index: 25, grapheme_length: 30, char_index: 27, char_length: 30, byte_index: 37, byte_length: 30}
      ], @subject.identify("I'm 🐈‍⬛ just full of 💚 for https://example.com?peeps=true <- this is awesome! ", Patterns::URL).pattern_ranges
      assert_equal [
        {substring: "https://example.com?peeps=true", grapheme_index: 27, grapheme_length: 30, char_index: 31, char_length: 30, byte_index: 48, byte_length: 30}
      ], @subject.identify("I'm 🐈‍⬛ just full of 💚 for 🐈‍⬛ https://example.com?peeps=true <- this is awesome! ", Patterns::URL).pattern_ranges
      assert_equal [
        {substring: "https://usher.dev/posts/2025-03-08-kill-your-feeds/", grapheme_index: 21, grapheme_length: 51, char_index: 21, char_length: 51, byte_index: 21, byte_length: 51}
      ], @subject.identify("I'm just full of for https://usher.dev/posts/2025-03-08-kill-your-feeds/ <- this is awesome! ", Patterns::URL).pattern_ranges

      assert_equal [
        {substring: "🧑‍🧑‍🧒‍🧒", grapheme_index: 7, grapheme_length: 1, char_index: 7, char_length: 7, byte_index: 7, byte_length: 25},
        {substring: "🧑‍🧑‍🧒‍🧒", grapheme_index: 31, grapheme_length: 1, char_index: 39, char_length: 7, byte_index: 64, byte_length: 25}
      ], @subject.identify("Humble 🧑‍🧑‍🧒‍🧒 with a 🐈‍⬛ but mostly a 🧑‍🧑‍🧒‍🧒 of humans", /🧑‍🧑‍🧒‍🧒/).pattern_ranges

      assert_equal [
        {substring: "🧑‍🧑‍🧒‍🧒a🐈‍⬛", grapheme_index: 15, grapheme_length: 3, char_index: 23, char_length: 11, byte_index: 48, byte_length: 36},
        {substring: "🧑‍🧑‍🧒‍🧒boop🐈‍⬛", grapheme_index: 32, grapheme_length: 6, char_index: 48, char_length: 14, byte_index: 98, byte_length: 39}
      ], @subject.identify("What if 🧑‍🧑‍🧒‍🧒🐈‍⬛ but 🧑‍🧑‍🧒‍🧒a🐈‍⬛ is sometimes 🧑‍🧑‍🧒‍🧒boop🐈‍⬛ but never 🧑‍🧑‍🧒‍🧒c🐈 in this", /🧑‍🧑‍🧒‍🧒\w+🐈‍⬛/).pattern_ranges

      assert_equal [
        {substring: "http://www.foo.co/🧑‍🧑‍🧒‍🧒🐈‍⬛", grapheme_index: 8, grapheme_length: 20, char_index: 8, char_length: 28, byte_index: 8, byte_length: 53},
        {substring: "https://me.com/pants?name=🧑‍🧑‍🧒‍🧒boop🐈‍⬛", grapheme_index: 37, grapheme_length: 32, char_index: 45, char_length: 40, byte_index: 70, byte_length: 65}
      ], @subject.identify("site 1: http://www.foo.co/🧑‍🧑‍🧒‍🧒🐈‍⬛ site 2: https://me.com/pants?name=🧑‍🧑‍🧒‍🧒boop🐈‍⬛ ", Patterns::URL).pattern_ranges

      # limit TLDs to top 200 known ones
      assert_empty @subject.identify("Sometimes at the end of sentences.he forgets to put a space after the period", Patterns::URL).pattern_ranges
    end

    def test_does_not_detect_emails_as_urls
      text = "Ping me at jerry@example.com or see https://example.com/contact"

      ranges = @subject.identify(text, Patterns::URL).pattern_ranges

      # Only the real URL should be detected; the email should not
      assert_equal [
        {
          substring: "https://example.com/contact",
          grapheme_index: 36,
          grapheme_length: 27,
          char_index: 36,
          char_length: 27,
          byte_index: 36,
          byte_length: 27
        }
      ], ranges
    end

    def test_hashtags
      # As of 1/22/25, only mastodon supports emoji in hashtags so just #foo will count at the end here
      assert_equal [
        {substring: "#cool", grapheme_index: 7, grapheme_length: 5, char_index: 7, char_length: 5, byte_index: 7, byte_length: 5},
        {substring: "#cat", grapheme_index: 13, grapheme_length: 4, char_index: 13, char_length: 4, byte_index: 13, byte_length: 4},
        {substring: "#foo", grapheme_index: 37, grapheme_length: 4, char_index: 37, char_length: 4, byte_index: 37, byte_length: 4}
      ], @subject.identify("I am a #cool #cat #1notavalidhashtag #foo🐈‍⬛", Patterns::HASHTAG).pattern_ranges
    end

    def test_adding_metadata
      assert_equal [
        {substring: "42", grapheme_index: 5, grapheme_length: 2, char_index: 5, char_length: 2, type: :number, byte_index: 5, byte_length: 2},
        {substring: "10", grapheme_index: 18, grapheme_length: 2, char_index: 18, char_length: 2, type: :number, byte_index: 18, byte_length: 2}
      ], @subject.identify("i am 42 years and 10 days old", /\d+/, metadata: {type: :number}).pattern_ranges
    end

    def test_transforms
      post = <<~MSG
        My ideas:
        * justin.searls.co/takes/2025-01-22-15h46m11s/
        * https://github.com/searls
        * https://searls.co
      MSG

      # The current results with no transformer:
      assert_equal [
        {substring: "justin.searls.co/takes/2025-01-22-15h46m11s/", grapheme_index: 12, grapheme_length: 44, char_index: 12, char_length: 44, byte_index: 12, byte_length: 44},
        {substring: "https://github.com/searls", grapheme_index: 59, grapheme_length: 25, char_index: 59, char_length: 25, byte_index: 59, byte_length: 25},
        {substring: "https://searls.co", grapheme_index: 87, grapheme_length: 17, char_index: 87, char_length: 17, byte_index: 87, byte_length: 17}
      ], @subject.identify(post, Patterns::URL).pattern_ranges

      result = @subject.identify(post, Patterns::URL, transformer: IdentifiesPatternRanges::URL_TO_DOMAIN_TRANSFORMER)

      assert_equal <<~EXP, result.string
        My ideas:
        * justin.searls.co
        * github.com
        * searls.co
      EXP
      assert_equal [
        {substring: "justin.searls.co/takes/2025-01-22-15h46m11s/", grapheme_index: 12, grapheme_length: 16, char_index: 12, char_length: 16, byte_index: 12, byte_length: 16},
        {substring: "https://github.com/searls", grapheme_index: 31, grapheme_length: 10, char_index: 31, char_length: 10, byte_index: 31, byte_length: 10},
        {substring: "https://searls.co", grapheme_index: 44, grapheme_length: 9, char_index: 44, char_length: 9, byte_index: 44, byte_length: 9}
      ], result.pattern_ranges
    end

    def test_tracks_byte_indices
      result = @subject.identify("hello 🐈cat", /cat/)
      assert_equal [
        {
          substring: "cat",
          grapheme_index: 7,
          grapheme_length: 3,
          char_index: 7,
          char_length: 3,
          byte_index: 10,   # "hello " -> 6 bytes, "🐈" -> 4 bytes, total 10
          byte_length: 3
        }
      ], result.pattern_ranges

      result = @subject.identify("hello 🐈cat", /cat/, transformer: ->(cat) { "🐈‍⬛" })
      assert_equal "hello 🐈🐈‍⬛", result.string
      assert_equal [
        {
          substring: "cat",
          grapheme_index: 7,
          grapheme_length: 1,
          char_index: 7,
          char_length: 3,
          byte_index: 10,   # "hello " -> 6 bytes, "🐈" -> 4 bytes, total 10
          byte_length: 10
        }
      ], result.pattern_ranges
    end
  end
end
