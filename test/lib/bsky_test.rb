require "test_helper"

class BskyTest < ActiveSupport::TestCase
  def test_bsky_syndication
    user = New.create(User, email: "user@example.com")
    feed = fake_feed_from(user, "2025-01-28-justin.searls.co.atom.xml")
    user.accounts.find_or_create_by!(platform_tag: "bsky", label: "Test Account", credentials: {
      email: "user@example.com",
      password: "password"
    })

    FetchesFeed.new.fetch!(feed, cache: false)

    # Post a take to bsky
    crosspost = Post.find_by(remote_id: "https://justin.searls.co/takes/2024-10-29-09h22m34s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("bsky_take", time: "2025-01-29T03:03:55.226Z") do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "at://did:plc:vvwq23uzqcsoekea65qzdddk/app.bsky.feed.post/3lgtybpyq7l23", crosspost.remote_id
    assert_equal "https://bsky.app/profile/alharrington.bsky.social/post/3lgtybpyq7l23", crosspost.url
    assert_equal "Three quick takes on ChatGPT integration in iOS 18.2:\n\n1. You can disable Siri prompting you for permission to query ChatGPT\n2. When using ChatGPT via Siri, you can type a follow-up and it’ll hold context and respond\n3. If you want to bypass vanilla Siri actions, you may need to preface... continued", crosspost.content

    # Post a Shot post
    crosspost = Post.find_by(remote_id: "https://justin.searls.co/shots/2024-10-28-09h56m20s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("bsky_shot", time: "2025-01-29T14:25:02.263Z") do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "at://did:plc:vvwq23uzqcsoekea65qzdddk/app.bsky.feed.post/3lgv6do363r2n", crosspost.remote_id
    assert_equal "https://bsky.app/profile/alharrington.bsky.social/post/3lgv6do363r2n", crosspost.url
    assert_equal "Orlando, I love you 🎶", crosspost.content
  end

  def test_bsky_link_fuckup
    user = New.create(User, email: "user@example.com")
    feed = fake_feed_from(user, "2025-03-12-justin.searls.co.atom.xml")
    user.accounts.find_or_create_by!(platform_tag: "bsky", label: "Test Account", credentials: {
      email: "user@example.com",
      password: "password"
    })

    FetchesFeed.new.fetch!(feed, cache: false)

    # Post the offending take to bsky
    crosspost = Post.find_by(remote_id: "https://justin.searls.co/takes/2025-03-08-16h39m24s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("bsky_cut_off_bug", time: "2025-03-12T22:02:45.990Z") do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "at://did:plc:vvwq23uzqcsoekea65qzdddk/app.bsky.feed.post/3lk7litc2yu2y", crosspost.remote_id
    assert_equal "https://bsky.app/profile/alharrington.bsky.social/post/3lk7litc2yu2y", crosspost.url
    assert_equal "Two words: POSSE Party usher.dev/…", crosspost.content
  end
end
