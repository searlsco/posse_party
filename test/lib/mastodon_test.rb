require "test_helper"

class MastodonTest < ActiveSupport::TestCase
  def test_syndication
    user = New.create(User, email: "user@example.com")
    feed = fake_feed_from(user, "2025-01-28-justin.searls.co.atom.xml")
    user.accounts.find_or_create_by!(platform_tag: "mastodon", label: "@testperson", credentials: {
      base_url: "https://mastodon.social",
      access_token: "SOME_TOKEN"
    })

    FetchesFeed.new.fetch!(feed, cache: false)

    crosspost = Post.find_by(remote_id: "https://justin.searls.co/takes/2024-10-26-13h47m04s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("mastodon_take") do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "113935658428064993", crosspost.remote_id
    assert_equal "https://mastodon.social/@searls/113935658428064993", crosspost.url
    assert_equal "Look, all I want from political news—literally the only thing I’m asking for, and it isn’t much—is to tell me the literal future exactly as it will unfold so that my brain can go back to focusing on anything else.", crosspost.content

    # Post a Shot post
    crosspost = Post.find_by(remote_id: "https://justin.searls.co/shots/2024-10-28-09h56m20s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("mastodon_shot") do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "113935670111298635", crosspost.remote_id
    assert_equal "https://mastodon.social/@searls/113935670111298635", crosspost.url
    assert_equal "Orlando, I love you 🎶 https://justin.searls.co/shots/2024-10-28-09h56m20s/", crosspost.content

    # Post a Take with hyperlinks that have been truncated (regression test to make sure we look at the href not the link content)
    crosspost = Post.find_by(remote_id: "https://justin.searls.co/takes/2025-01-22-15h46m11s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("mastodon_take_href") do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "113991777044908687", crosspost.remote_id
    assert_equal "https://mastodon.social/@alharrington/113991777044908687", crosspost.url
    assert_equal "\"How hard could it possibly be to truncate a string while making sure it doesn't cut off any URLs or hashtags?\" he asked, ignorantly. https://gist.github.com/searls/9d8ee42929da99ae268477eb20818da6", crosspost.content
  end
end
