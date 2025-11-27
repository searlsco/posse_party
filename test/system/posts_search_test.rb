require "application_system_test_case"

class PostsSearchTest < ApplicationSystemTestCase
  setup do
    @user = users(:admin)
    @feed = feeds(:admin_feed)

    # Create test posts
    @post1 = Post.create!(
      feed: @feed,
      url: "https://example.com/ruby-tutorial",
      remote_id: "ruby-1",
      title: "Ruby Programming Tutorial",
      summary: "Learn Ruby basics",
      remote_published_at: 1.day.ago
    )

    @post2 = Post.create!(
      feed: @feed,
      url: "https://example.com/javascript-guide",
      remote_id: "js-1",
      title: "JavaScript Guide",
      summary: "Modern JavaScript development",
      remote_published_at: 2.days.ago
    )

    # Create crossposts
    @user.accounts.each do |account|
      Crosspost.create!(post: @post1, account: account, status: :published)
      Crosspost.create!(post: @post2, account: account, status: :published)
    end

    login_as(@user)
  end

  test "search functionality with clear button" do
    visit posts_path

    # Initially, clear button should be hidden
    assert_selector :link, "Clear search", visible: false

    # Type in search field
    fill_in "Search posts by title, URL, content...", with: "Ruby"

    # Clear button should become visible after typing
    assert_selector :link, "Clear search", visible: true

    # Wait for debounced search via Capybara's default waiting

    # Should show only Ruby post
    assert_selector "h2", text: "Ruby Programming Tutorial"
    assert_no_selector "h2", text: "JavaScript Guide"

    # Click clear button
    click_on "Clear search"

    # Should show all posts again
    assert_selector "h2", text: "Ruby Programming Tutorial"
    assert_selector "h2", text: "JavaScript Guide"

    # Each post shows its feed label before the URL path
    assert_text "Admin's Blog:\n/ruby-tutorial"
    assert_text "Admin's Blog:\n/javascript-guide"

    # Clear button should be hidden again
    assert_selector :link, "Clear search", visible: false

    # Search field should be empty
    assert_field "Search posts by title, URL, content...", with: ""
  end

  test "visiting page with query parameter shows clear button" do
    visit posts_path(q: "JavaScript")

    # Clear button should be visible when page loads with query
    assert_selector :link, "Clear search", visible: true

    # Should show only JavaScript post
    assert_selector "h2", text: "JavaScript Guide"
    assert_no_selector "h2", text: "Ruby Programming Tutorial"

    # Clear the search
    click_on "Clear search"

    # Should navigate to posts_path without query
    assert_current_path posts_path
    assert_selector "h2", text: "Ruby Programming Tutorial"
    assert_selector "h2", text: "JavaScript Guide"
  end

  test "infinite scroll works with search results" do
    # Create many posts for testing infinite scroll (need more than 30 for pagination)
    now = Time.current
    posts_data = 31.times.map do |i|
      {
        feed_id: @feed.id,
        url: "https://example.com/test-#{i}",
        remote_id: "test-#{i}",
        title: "Test Post #{i}",
        summary: "Summary for test post #{i}",
        remote_published_at: (i + 3).days.ago,
        created_at: now,
        updated_at: now
      }
    end
    Post.insert_all(posts_data)
    post_ids = Post.where(feed_id: @feed.id).where("title LIKE 'Test Post %'").order(created_at: :desc).limit(31).pluck(:id)
    Crosspost.insert_all(post_ids.map { |pid| {post_id: pid, account_id: @user.accounts.first.id, status: "published", created_at: now, updated_at: now} })

    visit posts_path

    # Search for "Test"
    fill_in "Search posts by title, URL, content...", with: "Test"

    # Wait for search via Capybara's default waiting

    # First page shows results and a lazy-loading frame for the next page
    assert_selector "h2", text: "Test Post 0"
    assert_selector "turbo-frame[loading='lazy']"

    # Scroll to trigger infinite loading
    page.execute_script "window.scrollTo(0, document.body.scrollHeight)"

    # Force lazy frame to load
    page.execute_script <<~JS
      const lazyFrame = document.querySelector('turbo-frame[loading="lazy"]');
      if (lazyFrame) {
        lazyFrame.loading = 'eager';
        lazyFrame.reload();
      }
    JS

    # Should load more posts: final sentinel is visible
    assert_selector "h2", text: "Test Post 30"
  end

  test "no reset search link is shown" do
    visit posts_path(q: "something")

    # Should not have the old reset search link
    assert_no_text "Reset search"

    # But should have the clear button
    assert_selector :link, "Clear search", visible: true
  end
end
