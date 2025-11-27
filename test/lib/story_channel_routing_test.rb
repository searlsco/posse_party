require "test_helper"

class StoryChannelRoutingTest < ActiveSupport::TestCase
  def setup
    Platforms::Test.reset_interactions!
  end

  # (a) Skips unsupported platforms when global channel is 'story'.
  def test_skips_unsupported_platforms_for_story_channel
    user = New.create(User, email: "user@example.com")
    feed = New.create(Feed, user:)
    post = New.create(Post, feed:, platform_overrides: {"test" => {"channel" => "story"}})
    test_account = New.create(Account, user:, platform_tag: "test", label: "@test")
    crosspost = CreatesCrosspostForPost.new.create(user:, post:, account_id: test_account.id).data
    crosspost.update!(status: "wip")

    PublishesCrosspost.new.publish(crosspost.id)

    assert_equal "skipped", crosspost.reload.status
  end

  # (b) Defaults to 'feed' when channel is omitted.
  def test_defaults_to_feed_when_channel_omitted
    user = New.create(User, email: "user@example.com")
    feed = New.create(Feed, user:)
    post = New.create(Post, feed:)
    test_account = New.create(Account, user:, platform_tag: "test", label: "@test")
    crosspost = CreatesCrosspostForPost.new.create(user:, post:, account_id: test_account.id).data
    crosspost.update!(status: "wip")

    PublishesCrosspost.new.publish(crosspost.id)

    assert_equal "feed", Platforms::Test.interactions.last[:crosspost_config].channel
    assert_equal "published", crosspost.reload.status
  end
end
