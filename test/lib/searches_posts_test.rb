require "test_helper"

class SearchesPostsTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @searches_posts = SearchesPosts.new
  end

  test "returns failure when user is blank" do
    result = @searches_posts.search(nil, "test query")

    assert result.failure?
    assert_equal "User is required", result.error
  end

  test "returns failure when query is blank" do
    result = @searches_posts.search(@user, "")

    assert result.failure?
    assert_equal "Query cannot be blank", result.error
  end

  test "returns failure when query is nil" do
    result = @searches_posts.search(@user, nil)

    assert result.failure?
    assert_equal "Query cannot be blank", result.error
  end

  test "searches by post title" do
    post = posts(:admin_post)
    post.update!(title: "Unique Title Here")

    result = @searches_posts.search(@user, "Unique")

    assert result.success?
    assert_includes result.data[:posts], post
  end

  test "searches by post URL" do
    post = posts(:admin_post)
    post.update!(url: "https://example.com/unique-url")

    result = @searches_posts.search(@user, "unique-url")

    assert result.success?
    assert_includes result.data[:posts], post
  end

  test "searches by post content" do
    post = posts(:admin_post)
    post.update!(content: "This is unique content for testing")

    result = @searches_posts.search(@user, "unique content")

    assert result.success?
    assert_includes result.data[:posts], post
  end

  test "search is case insensitive" do
    post = posts(:admin_post)
    post.update!(title: "Testing CASE Insensitive")

    result = @searches_posts.search(@user, "testing case")

    assert result.success?
    assert_includes result.data[:posts], post
  end

  test "sanitizes SQL injection attempts" do
    result = @searches_posts.search(@user, "'; DROP TABLE posts; --")

    assert result.success?
    assert_empty result.data[:posts]
  end

  test "respects user scope - only returns user's posts" do
    users(:user)
    post = posts(:user_post)
    post.update!(title: "Should not be found")

    result = @searches_posts.search(@user, "Should not be found")

    assert result.success?
    assert_not_includes result.data[:posts], post
  end

  test "orders results by remote_published_at DESC" do
    old_post = posts(:user_post)
    new_post = posts(:admin_post)
    old_post.update!(title: "Test Post", remote_published_at: 2.days.ago)
    new_post.update!(title: "Test Post", remote_published_at: 1.day.ago)

    result = @searches_posts.search(@user, "Test Post")

    assert result.success?
    assert_equal new_post.id, result.data[:posts].first.id
  end

  test "handles pagination with page and per_page parameters" do
    # Create multiple posts with the same search term
    10.times do |i|
      Post.create!(
        feed: @user.feeds.first,
        title: "Paginated Post #{i}",
        url: "https://example.com/page#{i}",
        remote_id: "page#{i}",
        remote_published_at: i.hours.ago
      )
    end

    # Create at least one crosspost for each post to satisfy the joins
    Post.where(feed: @user.feeds.first).find_each do |post|
      unless Crosspost.exists?(post: post, account: @user.accounts.first)
        Crosspost.create!(
          post: post,
          account: @user.accounts.first,
          status: :ready
        )
      end
    end

    result = @searches_posts.search(@user, "Paginated", page: 1, per_page: 5)

    assert result.success?
    assert_equal 5, result.data[:posts].length
    assert_equal 1, result.data[:current_page]
    assert result.data[:has_more]
  end
end
