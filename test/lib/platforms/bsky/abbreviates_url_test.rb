require "test_helper"
class Platforms::Bsky
  class AbbreviatesUrlTest < ActiveSupport::TestCase
    setup do
      @subject = AbbreviatesUrl.new
    end
    def test_domains_that_have_a_shorter_domain
      assert_equal "usher.dev/…", @subject.call("https://usher.dev/posts/2025-03-08-kill-your-feeds/")
    end
  end
end
