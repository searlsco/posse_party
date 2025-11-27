require "test_helper"

class CreatesMissingCrosspostsForAccountTest < ActiveSupport::TestCase
  def test_creates_skipped_crossposts_for_posts_without_account_crosspost
    user = users(:user)
    post = posts(:user_post)
    post.update!(crossposts_created_at: Now.time)
    account = Account.create!(user:, platform_tag: "test", label: "Test Account")

    result = CreatesMissingCrosspostsForAccount.new.create(account:)

    crosspost = account.crossposts.find_by(post:)
    assert result.success?
    assert_not_nil crosspost
    assert_equal "skipped", crosspost.status
  end

  def test_does_not_duplicate_existing_crossposts
    user = users(:user)
    post = posts(:user_post)
    account = Account.create!(user:, platform_tag: "test", label: "Test Account")
    Crosspost.create!(account:, post:, status: "ready")

    result = CreatesMissingCrosspostsForAccount.new.create(account:)

    crossposts = account.crossposts.where(post:)
    assert result.success?
    assert_equal 1, crossposts.count
    assert_equal ["ready"], crossposts.pluck(:status)
  end

  def test_returns_success_without_creating_when_account_inactive
    user = users(:user)
    post = posts(:user_post)
    account = Account.create!(user:, platform_tag: "test", label: "Inactive Account", active: false)

    result = CreatesMissingCrosspostsForAccount.new.create(account:)

    assert result.success?
    assert_nil account.crossposts.find_by(post:)
    assert_nil post.reload.crossposts_created_at
  end

  def test_returns_success_without_creating_when_account_disables_crossposts
    user = users(:user)
    post = posts(:user_post)
    account = Account.create!(user:, platform_tag: "test", label: "Disabled Account", manually_create_crossposts: true)

    result = CreatesMissingCrosspostsForAccount.new.create(account:)

    assert result.success?
    assert_nil account.crossposts.find_by(post:)
    assert_nil post.reload.crossposts_created_at
  end

  def test_ignores_posts_from_feeds_with_crossposting_disabled
    user = users(:user)
    allowed_post = posts(:user_post)
    blocked_post = Post.create!(
      feed: Feed.create!(user:, label: "Disabled Feed", url: "https://user.example.com/disabled.xml", automatically_create_crossposts: false),
      url: "https://user.example.com/disabled-post",
      remote_id: "disabled-post"
    )
    account = Account.create!(user:, platform_tag: "test", label: "Feed Filter Account")

    result = CreatesMissingCrosspostsForAccount.new.create(account:)

    assert result.success?
    assert Crosspost.exists?(account:, post: allowed_post)
    refute Crosspost.exists?(account:, post: blocked_post)
    assert_nil blocked_post.reload.crossposts_created_at
  end

  def test_ignores_posts_from_account_disabled_feed_ids
    user = users(:user)
    allowed_post = posts(:user_post)
    blocked_feed = Feed.create!(user:, label: "Blocked Feed", url: "https://user.example.com/blocked.xml", automatically_create_crossposts: true)
    blocked_post = Post.create!(feed: blocked_feed, url: "https://user.example.com/blocked-post", remote_id: "blocked-post")
    account = Account.create!(user:, platform_tag: "test", label: "Feed Filter Account", disabled_feed_ids: [blocked_feed.id])

    result = CreatesMissingCrosspostsForAccount.new.create(account:)

    assert result.success?
    assert Crosspost.exists?(account:, post: allowed_post)
    refute Crosspost.exists?(account:, post: blocked_post)
    assert_nil blocked_post.reload.crossposts_created_at
  end

  def test_backfills_for_posts_that_already_have_crossposts_for_other_accounts
    user = users(:user)
    post = posts(:user_post)

    # Existing account already has a crosspost for this post
    existing_account = Account.create!(user:, platform_tag: "test", label: "Existing")
    Crosspost.create!(account: existing_account, post:, status: "ready")

    # New account should still get a crosspost backfilled for the same post
    new_account = Account.create!(user:, platform_tag: "test", label: "New")

    result = CreatesMissingCrosspostsForAccount.new.create(account: new_account)

    assert result.success?
    crosspost = new_account.crossposts.find_by(post:)
    assert_not_nil crosspost
    assert_equal "skipped", crosspost.status
  end
end
