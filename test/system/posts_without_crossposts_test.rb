require "application_system_test_case"

class PostsWithoutCrosspostsTest < ApplicationSystemTestCase
  setup do
    login_as(users(:admin))
  end

  def test_posts_without_crossposts_are_rendered
    visit posts_path

    shared_post = posts(:admin_post)
    unshared_post = posts(:admin_post_without_crossposts)

    assert_selector "h2", text: shared_post.title
    assert_selector "h2", text: unshared_post.title

    within "[data-post-id='#{shared_post.id}']" do
      assert_selector "a[href^='/crossposts/']"
    end

    within "[data-post-id='#{unshared_post.id}']" do
      assert_no_selector "a[href^='/crossposts/']"
    end
  end

  def test_prompt_displayed_when_posts_and_no_accounts
    user_without_accounts = New.create(User)
    feed = New.create(Feed, user: user_without_accounts)
    New.create(Post, feed: feed, title: "Standalone Post 1")
    New.create(Post, feed: feed, title: "Standalone Post 2", remote_published_at: Now.ago(1.day))

    login_as(user_without_accounts)

    visit posts_path

    assert_selector "h2", text: "Add an account to start syndicating"
    assert_selector "h2", text: "Standalone Post 1"
    assert_selector "h2", text: "Standalone Post 2"
  end
end
