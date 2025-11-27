require "application_system_test_case"

class FirstLaunchTest < ApplicationSystemTestCase
  def setup
    # Clear all data to simulate fresh install
    truncate_all_tables
  end

  private

  def user_row_for(email)
    find("turbo-frame##{dom_id(User.find_by!(email: email), :row)}")
  end

  def delete_user(email)
    within user_row_for(email) do
      click_button "Delete"
    end

    within find("dialog[open]") do
      fill_in "Type #{email} to confirm", with: email
      click_button "Delete user"
    end
  end

  test "complete first launch experience from empty database" do
    # 1. First launch redirects to registration
    visit root_path
    assert_current_path "/auth/register"
    assert_text "Create your account"

    # 2. Register the first admin user
    admin_email = "admin@example.com"
    fill_in "Email", with: admin_email
    fill_in "Password", with: "LaunchPass!1"
    fill_in "Password confirmation", with: "LaunchPass!1"
    click_button "Register"

    # Should redirect to posts since password registration logs in immediately
    assert_current_path posts_path
    assert_text "You are now logged in"

    visit settings_path

    # Verify admin user was created properly
    admin = User.first
    assert admin.admin?
    assert admin.api_key.present?

    # 3. Test that registration is now disabled
    visit "/auth/logout"  # Direct logout
    visit "/auth/register"
    assert_current_path "/auth/register"
    assert_equal 1, User.count

    # 4. Log back in as admin and invite a user
    visit "/test/session?key=user_id&value=#{admin.id}"
    visit settings_path
    assert_text "Users"
    click_link "Invite User"

    test_user_email = "testuser@example.com"
    fill_in "Email", with: test_user_email
    click_button "Invite User"

    assert_current_path settings_path
    assert_text "Invitation sent to #{test_user_email}."
    assert Invite.open.for_email(test_user_email).exists?

    # 5. Invited user registers via the invite
    click_link "Log out"
    visit "/auth/register"
    fill_in "Email", with: test_user_email
    fill_in "Password", with: "AnotherPass!1"
    fill_in "Password confirmation", with: "AnotherPass!1"
    click_button "Register"

    assert_current_path posts_path
    assert_text "You are now logged in"

    User.find_by(email: test_user_email)
    refute Invite.open.for_email(test_user_email).exists?

    # Verify non-admin cannot see user management
    visit settings_path
    assert_no_text "Users"
    assert_no_text "Invite User"

    # 6. Create a feed as test user
    visit feeds_path
    click_link "Add Feed"

    fill_in "Label", with: "Test Blog"
    fill_in "URL", with: test_feed_fixture_url("2025-07-08-justin.searls.co.atom.xml")
    click_button "Save"

    assert_text "Feed created successfully"

    # 7. Create an account with manual publish
    visit accounts_path
    click_link "Add Account"

    fill_in "Label", with: "Test Bluesky"
    select "Bluesky", from: "Platform"

    # Wait for credential fields to load via Turbo
    assert_text "Credentials for Bluesky"

    # Fill in credentials
    fill_in "Email", with: "test@bsky.social"
    fill_in "Password", with: "dummypass"
    check "Manually publish crossposts"
    click_button "Create Account"

    assert_text "Account created successfully"

    # 8. Check the feed to create posts and crossposts
    feed = Feed.find_by(label: "Test Blog")
    visit edit_feed_path(feed)

    # Mock feed fetch to create posts
    Post.create!(
      feed: feed,
      title: "Test Post",
      content: "Test content",
      url: "https://example.com/post1",
      remote_id: "post1",
      remote_published_at: 1.hour.ago
    )

    # Create crossposts
    account = Account.find_by(label: "Test Bluesky")
    Crosspost.create!(
      account: account,
      post: Post.last,
      status: "ready"
    )

    visit posts_path
    assert_text "Test Post"
    assert_text "Ready"
    assert_text "Test Bluesky"

    # 9. Log back in as admin and verify data isolation
    visit "/test/session?key=user_id&value=#{admin.id}"

    # Admin should not see test user's data
    visit feeds_path
    assert_no_text "Test Blog"

    visit accounts_path
    assert_no_text "Test Bluesky"

    visit posts_path
    assert_text "No crossposts yet"

    # 10. Delete the test user and verify cascade
    visit settings_path

    delete_user(test_user_email)

    assert_text "User deleted successfully"
    assert_no_text test_user_email

    # Verify all data was deleted
    assert_equal 0, Account.count
    assert_equal 0, Feed.count
    assert_equal 0, Post.count
    assert_equal 0, Crosspost.count
    assert_equal 1, User.count # Only admin remains
  end

  # (Removed duplicate API key regeneration test; covered in UserManagementTest)
end
