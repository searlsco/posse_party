require "test_helper"

class CrosspostContentNewlinePreservationTest < ActiveSupport::TestCase
  def test_preserves_newlines_in_crosspost_content
    Platforms::Test.reset_interactions!
    user = users(:user)
    feed = fake_feed_from(user, "2025-07-01-justin.searls.co.atom.xml")
    user.accounts.find_or_create_by!(platform_tag: "test", label: "@testuser", credentials: {})

    FetchesFeed.new.fetch!(feed, cache: false)
    post = Post.find_by(remote_id: "https://justin.searls.co/takes/2025-07-01-09h33m43s/")
    crosspost = post.crossposts.joins(:account).where(accounts: {platform_tag: "test"}).first
    crosspost.update!(status: "wip")
    PublishesCrosspost.new.publish(crosspost.id)

    content = Platforms::Test.interactions.first[:crosspost_content].string
    assert content.include?("2008: Social Network\n2014: Social Media\n2025: Content Platform"), "Content should preserve newlines between lines"
  end
end
