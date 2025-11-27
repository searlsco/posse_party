require "test_helper"

class FeedTest < ActiveSupport::TestCase
  setup do
    @user = New.create(User, email: "feedtester@example.com")
  end

  def test_validates_url
    feed = @user.feeds.build(label: "Test", url: "ftp://example.com/feed")

    refute feed.valid?
    assert_includes feed.errors[:url], "must be a valid URL"

    feed.url = "http://example.com/feed.xml"
    assert feed.valid?

    feed.url = "https://example.com/feed.xml"
    assert feed.valid?
  end
end
