require "test_helper"

class FetchesFeedCreatesCrosspostsTest < ActiveSupport::TestCase
  def test_marks_all_skipped_on_first_fetch
    feed = feeds(:user_feed)
    account1 = accounts(:user_x_account)
    account2 = accounts(:user_linkedin_account)
    accounts(:user_youtube_account).update!(manually_create_crossposts: true)

    feed.update!(automatically_create_crossposts: true)
    account1.update!(manually_create_crossposts: false)
    account2.update!(manually_create_crossposts: false)

    post = Post.create!(
      feed: feed,
      url: "https://user.example.com/first",
      remote_id: "first",
      remote_published_at: 2.days.ago,
      remote_updated_at: 2.days.ago,
      title: "First",
      content: "first"
    )

    subject = FetchesFeed::CreatesCrossposts.new

    subject.create!(feed, published_after: nil, skip_posts_older_than: nil)

    assert_equal %w[skipped skipped],
      Crosspost.where(post: post).order(:account_id).pluck(:status)
  end

  def test_marks_backfilled_posts_as_skipped_and_new_posts_as_ready
    feed = feeds(:user_feed)
    account1 = accounts(:user_x_account)
    account2 = accounts(:user_linkedin_account)
    accounts(:user_youtube_account).update!(manually_create_crossposts: true) # exclude from auto-create

    feed.update!(automatically_create_crossposts: true)
    account1.update!(manually_create_crossposts: false)
    account2.update!(manually_create_crossposts: false)

    existing_post = Post.create!(
      feed: feed,
      url: "https://user.example.com/existing",
      remote_id: "existing",
      remote_published_at: 2.days.ago,
      remote_updated_at: 2.days.ago,
      title: "Existing",
      content: "existing"
    )

    subject = FetchesFeed::CreatesCrossposts.new
    skip_posts_older_than = existing_post.remote_published_at

    subject.create!(feed, published_after: nil, skip_posts_older_than: skip_posts_older_than)

    backfilled_post = Post.create!(
      feed: feed,
      url: "https://user.example.com/backfilled",
      remote_id: "backfilled",
      remote_published_at: 3.days.ago,
      remote_updated_at: 3.days.ago,
      title: "Backfilled",
      content: "backfilled"
    )

    new_post = Post.create!(
      feed: feed,
      url: "https://user.example.com/new",
      remote_id: "new",
      remote_published_at: 10.minutes.ago,
      remote_updated_at: 10.minutes.ago,
      title: "New",
      content: "new"
    )

    subject.create!(feed, published_after: 30.minutes.ago, skip_posts_older_than: skip_posts_older_than)

    assert_equal %w[skipped skipped],
      Crosspost.where(post: backfilled_post).order(:account_id).pluck(:status)
    assert_equal %w[skipped skipped],
      Crosspost.where(post: existing_post).order(:account_id).pluck(:status)
    assert_equal %w[ready ready],
      Crosspost.where(post: new_post).order(:account_id).pluck(:status)
  end

  def test_marks_undated_posts_as_ready_after_first_check_when_both_dates_missing
    feed = feeds(:user_feed)
    account1 = accounts(:user_x_account)
    account2 = accounts(:user_linkedin_account)
    accounts(:user_youtube_account).update!(manually_create_crossposts: true)

    feed.update!(automatically_create_crossposts: true)
    account1.update!(manually_create_crossposts: false)
    account2.update!(manually_create_crossposts: false)

    undated_post = Post.create!(
      feed: feed,
      url: "https://user.example.com/undated",
      remote_id: "undated",
      remote_published_at: nil,
      remote_updated_at: nil,
      title: "Undated",
      content: "undated"
    )

    subject = FetchesFeed::CreatesCrossposts.new

    subject.create!(feed, published_after: 30.minutes.ago, skip_posts_older_than: nil)

    assert_equal %w[ready ready], Crosspost.where(post: undated_post).order(:account_id).pluck(:status)
  end

  def test_marks_undated_but_recently_updated_posts_as_ready_after_first_check
    feed = feeds(:user_feed)
    account1 = accounts(:user_x_account)
    account2 = accounts(:user_linkedin_account)
    accounts(:user_youtube_account).update!(manually_create_crossposts: true)

    feed.update!(automatically_create_crossposts: true)
    account1.update!(manually_create_crossposts: false)
    account2.update!(manually_create_crossposts: false)

    undated_recent = Post.create!(
      feed: feed,
      url: "https://user.example.com/undated-recent",
      remote_id: "undated-recent",
      remote_published_at: nil,
      remote_updated_at: 10.minutes.ago,
      title: "Undated recent",
      content: "undated recent"
    )

    subject = FetchesFeed::CreatesCrossposts.new
    skip_posts_older_than = 30.minutes.ago

    subject.create!(feed, published_after: 30.minutes.ago, skip_posts_older_than: skip_posts_older_than)

    assert_equal %w[ready ready], Crosspost.where(post: undated_recent).order(:account_id).pluck(:status)
  end

  def test_marks_undated_and_old_updated_posts_as_skipped_after_first_check
    feed = feeds(:user_feed)
    account1 = accounts(:user_x_account)
    account2 = accounts(:user_linkedin_account)
    accounts(:user_youtube_account).update!(manually_create_crossposts: true)

    feed.update!(automatically_create_crossposts: true)
    account1.update!(manually_create_crossposts: false)
    account2.update!(manually_create_crossposts: false)

    existing_post = Post.create!(
      feed: feed,
      url: "https://user.example.com/existing",
      remote_id: "existing",
      remote_published_at: 1.day.ago,
      remote_updated_at: 1.day.ago,
      title: "Existing",
      content: "existing"
    )

    subject = FetchesFeed::CreatesCrossposts.new
    skip_posts_older_than = existing_post.remote_published_at

    subject.create!(feed, published_after: nil, skip_posts_older_than: skip_posts_older_than)

    undated_old = Post.create!(
      feed: feed,
      url: "https://user.example.com/undated-old",
      remote_id: "undated-old",
      remote_published_at: nil,
      remote_updated_at: 3.days.ago,
      title: "Undated old",
      content: "undated old"
    )

    subject.create!(feed, published_after: 30.minutes.ago, skip_posts_older_than: skip_posts_older_than)

    assert_equal %w[skipped skipped], Crosspost.where(post: undated_old).order(:account_id).pluck(:status)
  end

  def test_skips_when_feed_disables_crossposts
    feed = feeds(:user_feed)
    account = accounts(:user_x_account)
    alternate_account = accounts(:user_linkedin_account)
    post = posts(:user_post)
    feed.update!(automatically_create_crossposts: false)
    account.update!(manually_create_crossposts: false)
    alternate_account.update!(manually_create_crossposts: false)

    subject = FetchesFeed::CreatesCrossposts.new

    subject.create!(feed, published_after: Now.time, skip_posts_older_than: nil)

    assert_equal 0, Crosspost.where(post: post).count
    assert_nil post.reload.crossposts_created_at
  end

  def test_skips_accounts_with_crossposting_disabled
    feed = feeds(:user_feed)
    allowed_account = accounts(:user_x_account)
    blocked_account = accounts(:user_linkedin_account)
    post = posts(:user_post)
    feed.update!(automatically_create_crossposts: true)
    allowed_account.update!(manually_create_crossposts: false)
    blocked_account.update!(manually_create_crossposts: true)

    subject = FetchesFeed::CreatesCrossposts.new

    subject.create!(feed, published_after: Now.time, skip_posts_older_than: nil)

    assert Crosspost.exists?(account: allowed_account, post: post)
    refute Crosspost.exists?(account: blocked_account, post: post)
    refute_nil post.reload.crossposts_created_at
  end

  def test_skips_accounts_with_disabled_feed_ids
    feed = feeds(:user_feed)
    allowed_account = accounts(:user_x_account)
    blocked_account = accounts(:user_linkedin_account)
    post = posts(:user_post)

    feed.update!(automatically_create_crossposts: true)
    allowed_account.update!(manually_create_crossposts: false)
    blocked_account.update!(manually_create_crossposts: false, disabled_feed_ids: [feed.id])

    subject = FetchesFeed::CreatesCrossposts.new

    subject.create!(feed, published_after: Now.time, skip_posts_older_than: nil)

    assert Crosspost.exists?(account: allowed_account, post: post)
    refute Crosspost.exists?(account: blocked_account, post: post)
    refute_nil post.reload.crossposts_created_at
  end
end
