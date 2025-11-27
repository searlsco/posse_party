require "test_helper"

class Platforms::Mastodon
  class CountsTootTest < ActiveSupport::TestCase
    setup do
      @subject = CountsToot.new
    end

    def test_counts_toots
      assert_equal 1, @subject.call("a")
      assert_equal 500, @subject.call("a" * 500)
      assert_equal 501, @subject.call("a" * 501)
      assert_equal 1000, @subject.call("a" * 1000)

      assert_equal 1, @subject.call("👨‍👩‍👧‍👦")
      assert_equal 4, @subject.call("👨‍👩‍👧‍👦👨‍👩‍👧‍👦👨‍👩‍👧‍👦👨‍👩‍👧‍👦")

      # URLs that start with http/https protocols are replaced with 23 characters
      assert_equal 47, @subject.call("https://example.com/this-is-a-very-long-url-that-should-be-truncated https://t.co")
      # URLs that aren't, aren't
      assert_equal 27, @subject.call("my favorite site is aol.com")

      # User domains are not counted
      assert_equal 17, @subject.call("Way to go @searls")
      assert_equal 17, @subject.call("Way to go @searls@threads.net")
    end
  end
end
