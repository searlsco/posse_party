require "application_system_test_case"

class PostCrosspostManagementTest < ApplicationSystemTestCase
  setup do
    @user = New.create(User)
    @feed = New.create(Feed, user: @user)
    @post = New.create(Post, feed: @feed, title: "Needs Crosspost")
    @account = New.create(Account, user: @user, platform_tag: "bsky", label: "@needs_crosspost", active: true)

    login_as(@user)
  end

  def test_create_crosspost_from_show
    visit post_path(@post)

    assert_selector "option", text: "Select an account"
    select @account.notification_label, from: "Account"
    click_button "Create Crosspost"

    assert_text "Created crosspost for #{@account.notification_label}"

    visit post_path(@post)
    assert_includes find_field("Account", disabled: true).text, "All crossposts created"
    assert find_field("Account", disabled: true)[:disabled]
    assert find_button("Create Crosspost", disabled: true)[:disabled]

    assert_selector "h2", text: "Crossposts (1)"
    assert_selector "div", text: @account.notification_label

    # Delete the post from the Manage section
    accept_confirm("Are you sure you want to delete this post? This will permanently delete the post and all 1 crosspost(s). This action cannot be undone.") do
      click_link "Delete Post"
    end

    assert_current_path posts_path
    assert_text "Post deleted successfully."
  end
end
