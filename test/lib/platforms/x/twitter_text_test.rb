require "test_helper"

class Platforms::X
  class TwitterTextTest < ActiveSupport::TestCase
    def test_hashtag_pattern
      assert_equal ["#am", "#super", "#cool"], "#am #super  howdy there\n    #cool".scan(TwitterText::HASHTAG_PATTERN)
    end

    def test_url_pattern
      assert_equal ["justin.searls.co", "www.aol.com?cool=beans"], "Site 1: justin.searls.co / Site 2: www.aol.com?cool=beans Neat!".scan(TwitterText::URL_PATTERN)
    end
  end
end
