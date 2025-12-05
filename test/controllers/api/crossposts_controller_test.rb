require "test_helper"

class Api::CrosspostsControllerTest < ActionDispatch::IntegrationTest
  test "returns 401 when no authorization header is provided" do
    get api_crossposts_path, params: {id: "test-id"}

    assert_response :unauthorized
    assert_equal({"error" => "Authorization header is required"}, JSON.parse(response.body))
  end

  test "returns 401 when authorization header is blank" do
    get api_crossposts_path,
      params: {id: "test-id"},
      headers: {"Authorization" => ""}

    assert_response :unauthorized
    assert_equal({"error" => "Authorization header is required"}, JSON.parse(response.body))
  end

  test "returns 401 when authorization header has no Bearer prefix" do
    get api_crossposts_path,
      params: {id: "test-id"},
      headers: {"Authorization" => "invalid-token"}

    assert_response :unauthorized
    assert_equal({"error" => "Authorization header is required"}, JSON.parse(response.body))
  end

  test "returns 401 when API key is invalid" do
    get api_crossposts_path,
      params: {id: "test-id"},
      headers: {"Authorization" => "Bearer invalid-api-key"}

    assert_response :unauthorized
    assert_equal({"error" => "Invalid API key"}, JSON.parse(response.body))
  end

  test "returns all crossposts when id parameter is missing" do
    user = users(:admin)

    # Set up crossposts with URLs
    bsky_crosspost = crossposts(:admin_bsky_crosspost)
    bsky_crosspost.update!(url: "https://bsky.app/profile/test.bsky.social/post/abc123", status: "published")

    mastodon_crosspost = crossposts(:admin_mastodon_crosspost)
    mastodon_crosspost.update!(url: "https://mastodon.social/@test/123456789", status: "published")

    get api_crossposts_path,
      headers: {"Authorization" => "Bearer #{user.api_key}"}

    assert_response :success

    response_data = JSON.parse(response.body)
    assert response_data.key?("crossposts")
    assert response_data.key?("updated_at")

    crossposts = response_data["crossposts"]
    assert crossposts.key?(posts(:admin_post).remote_id)
    assert_equal 2, crossposts[posts(:admin_post).remote_id].length

    # Ensure new fields present on items
    item = crossposts[posts(:admin_post).remote_id].first
    assert item.key?("status")
    assert item.key?("crosspost_url")
    assert item.key?("error")
  end

  test "returns all crossposts when id parameter is blank" do
    user = users(:admin)

    # Set up crossposts with URLs
    bsky_crosspost = crossposts(:admin_bsky_crosspost)
    bsky_crosspost.update!(url: "https://bsky.app/profile/test.bsky.social/post/abc123", status: "published")

    get api_crossposts_path,
      params: {id: ""},
      headers: {"Authorization" => "Bearer #{user.api_key}"}

    assert_response :success

    response_data = JSON.parse(response.body)
    assert response_data.key?("crossposts")
    assert response_data.key?("updated_at")
  end

  test "returns 404 when post does not exist" do
    user = users(:admin)

    get api_crossposts_path,
      params: {id: "non-existent-remote-id"},
      headers: {"Authorization" => "Bearer #{user.api_key}"}

    assert_response :not_found
    assert_equal({"error" => "Post not found"}, JSON.parse(response.body))
  end

  test "returns 404 when post exists but user has no crossposts for it" do
    user = users(:user)
    admin_post = posts(:admin_post)

    get api_crossposts_path,
      params: {id: admin_post.remote_id},
      headers: {"Authorization" => "Bearer #{user.api_key}"}

    assert_response :not_found
    assert_equal({"error" => "Post not found"}, JSON.parse(response.body))
  end

  test "returns empty array when post has crossposts but none have urls" do
    user = users(:admin)
    post = posts(:admin_post)

    # Ensure crosspost exists but has no URL
    crosspost = crossposts(:admin_bsky_crosspost)
    crosspost.update!(url: nil)

    get api_crossposts_path,
      params: {id: post.remote_id},
      headers: {"Authorization" => "Bearer #{user.api_key}"}

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test "returns crossposts for user's published crossposts with urls and includes status, crosspost_url, and error" do
    user = users(:admin)
    post = posts(:admin_post)

    # Set up crossposts with URLs
    bsky_crosspost = crossposts(:admin_bsky_crosspost)
    bsky_crosspost.update!(url: "https://bsky.app/profile/test.bsky.social/post/abc123", status: "published")

    mastodon_crosspost = crossposts(:admin_mastodon_crosspost)
    mastodon_crosspost.update!(url: "https://mastodon.social/@test/123456789", status: "published")

    get api_crossposts_path,
      params: {id: post.remote_id},
      headers: {"Authorization" => "Bearer #{user.api_key}"}

    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal 2, response_data.length

    # Check Bluesky crosspost
    bsky_item = response_data.find { |item| item["platform"] == "bsky" }
    assert_equal "Bluesky Test", bsky_item["account"]
    assert_equal "https://bsky.app/profile/test.bsky.social/post/abc123", bsky_item["url"]
    assert_equal "published", bsky_item["status"]
    assert_match %r{^http://www.example.com/crossposts/\d+$}, bsky_item["crosspost_url"]
    assert_nil bsky_item["error"]

    # Check Mastodon crosspost
    mastodon_item = response_data.find { |item| item["platform"] == "mastodon" }
    assert_equal "Mastodon Test", mastodon_item["account"]
    assert_equal "https://mastodon.social/@test/123456789", mastodon_item["url"]
    assert_equal "published", mastodon_item["status"]
    assert_match %r{^http://www.example.com/crossposts/\d+$}, mastodon_item["crosspost_url"]
    assert_nil mastodon_item["error"]
  end

  test "only returns crossposts belonging to the authenticated user" do
    user = users(:user)
    users(:admin)

    # Use user's post since the user needs to own the feed to see the post
    post = posts(:user_post)

    # Create user's crosspost
    user_account = accounts(:user_x_account)
    post.crossposts.create!(
      account: user_account,
      status: "published",
      url: "https://x.com/user/status/999"
    )

    # Create admin's crosspost on the same post
    admin_account = accounts(:admin_bsky_account)
    post.crossposts.create!(
      account: admin_account,
      status: "published",
      url: "https://bsky.app/profile/admin.bsky.social/post/xyz"
    )

    # Request as user - should only see user's crosspost
    get api_crossposts_path,
      params: {id: post.remote_id},
      headers: {"Authorization" => "Bearer #{user.api_key}"}

    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal 1, response_data.length
    assert_equal "x", response_data[0]["platform"]
    assert_equal "X Test", response_data[0]["account"]
    assert_equal "https://x.com/user/status/999", response_data[0]["url"]
  end

  test "handles various crosspost statuses correctly" do
    user = users(:admin)
    post = posts(:admin_post)

    # Update existing crossposts rather than creating new ones
    bsky_crosspost = crossposts(:admin_bsky_crosspost)
    bsky_crosspost.update!(status: "published", url: "https://bsky.app/profile/test/post/1")

    mastodon_crosspost = crossposts(:admin_mastodon_crosspost)
    mastodon_crosspost.update!(status: "ready", url: nil)

    # Create new crosspost for X account
    post.crossposts.create!(
      account: accounts(:admin_x_account),
      status: "failed",
      url: "https://x.com/test/status/1"
    )

    get api_crossposts_path,
      params: {id: post.remote_id},
      headers: {"Authorization" => "Bearer #{user.api_key}"}

    assert_response :success

    response_data = JSON.parse(response.body)
    platforms = response_data.pluck("platform")

    assert_includes platforms, "bsky"
    assert_includes platforms, "x"
    assert_not_includes platforms, "mastodon"
  end

  test "returns all crossposts ordered by most recent post update" do
    user = users(:admin)

    # Create additional post for testing ordering
    newer_post = feeds(:admin_feed).posts.create!(
      remote_id: "https://example.com/newer-post",
      url: "https://example.com/newer-post",
      title: "Newer Post",
      content: "Newer content",
      remote_published_at: 1.hour.ago
    )

    newer_post.crossposts.create!(
      account: accounts(:admin_bsky_account),
      status: "published",
      url: "https://bsky.app/profile/test/post/newer"
    )

    # Update older post crosspost
    older_post = posts(:admin_post)
    crossposts(:admin_mastodon_crosspost).update!(
      url: "https://mastodon.social/@test/older",
      status: "published"
    )

    # Touch the newer post to ensure it has the most recent updated_at
    newer_post.touch

    get api_crossposts_path,
      headers: {"Authorization" => "Bearer #{user.api_key}"}

    assert_response :success

    response_data = JSON.parse(response.body)
    crossposts = response_data["crossposts"]

    # Should have both posts
    assert_equal 2, crossposts.keys.length
    assert crossposts.key?(newer_post.remote_id)
    assert crossposts.key?(older_post.remote_id)

    # The updated_at should be from the most recent post
    assert_equal newer_post.updated_at.iso8601, response_data["updated_at"]
  end

  test "includes most recent failure message in error field when present" do
    user = users(:admin)
    post = posts(:admin_post)

    cp = crossposts(:admin_bsky_crosspost)
    cp.update!(
      url: "https://bsky.app/profile/test.bsky.social/post/has-error",
      status: "failed",
      failures: [{"message" => "Boom", "time" => Time.now.utc}]
    )

    get api_crossposts_path,
      params: {id: post.remote_id},
      headers: {"Authorization" => "Bearer #{user.api_key}"}

    assert_response :success
    response_data = JSON.parse(response.body)
    item = response_data.find { |i| i["platform"] == "bsky" }
    assert_equal "Boom", item["error"]
  end
end
