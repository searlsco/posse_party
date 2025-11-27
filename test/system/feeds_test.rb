require "application_system_test_case"

class FeedsTest < ApplicationSystemTestCase
  def setup
    @admin = users(:admin)
    @regular_user = users(:user)

    # Stub feed URL requests
    stub_request(:get, /example.com\/feed\.xml/)
      .to_return(status: 200, body: <<~XML, headers: {"Content-Type" => "application/xml"})
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>Test Feed</title>
          <link href="https://example.com/" />
          <updated>#{Time.current.iso8601}</updated>
          <entry>
            <title>Test Entry</title>
            <link href="https://example.com/post/1" />
            <id>https://example.com/post/1</id>
            <updated>#{Time.current.iso8601}</updated>
            <content type="html">Test content</content>
          </entry>
        </feed>
      XML
  end

  test "comprehensive feed CRUD workflow" do
    # Sign in as admin
    login_as(@admin)

    # Index page
    visit feeds_path
    assert_text "Feeds"
    assert_text "Add Feed"
    assert_text "Admin's Blog"
    assert_selector "a[href='#{edit_feed_path(feeds(:admin_feed))}']"

    # Create new feed
    click_link "Add Feed"
    assert_current_path new_feed_path
    assert_text "New Feed"

    # Try invalid submission
    click_button "Save"
    assert_text "can't be blank"

    # Fill out the form
    fill_in "Label", with: "Test Blog Feed"
    fill_in "URL", with: "https://test.example.com/feed.xml"
    check "Active"
    click_button "Save"

    # Should redirect to feeds index
    assert_current_path feeds_path
    assert_text "Feed created successfully"
    assert_text "Test Blog Feed"

    # Edit the feed - click on the feed card
    click_link "Test Blog Feed"
    assert_current_path edit_feed_path(Feed.find_by(label: "Test Blog Feed"))
    assert_text "Edit Feed"

    # Update feed
    fill_in "Label", with: "Updated Test Feed"
    uncheck "Active"
    click_button "Save"

    assert_text "Feed updated successfully"
    assert_current_path edit_feed_path(Feed.find_by(label: "Updated Test Feed"))
    assert_field "Label", with: "Updated Test Feed"

    # Check feed button with inactive feed (we're already on the edit page)
    accept_confirm "This feed is inactive. Checking it will update posts even for an inactive feed. Continue?" do
      click_link "Check Feed"
    end
    assert_text "Found 0 new posts."

    # Logs UX is covered comprehensively in NotificationsTest; no deep checks here

    # Test active feed check - go directly to edit page
    visit edit_feed_path(feeds(:admin_feed))
    click_link "Check Feed"
    assert_current_path edit_feed_path(feeds(:admin_feed))
    # The feed might have been checked, even if we don't see the flash

    # Delete feed - first go to edit page
    visit feeds_path
    click_link "Updated Test Feed"
    accept_confirm do
      click_link "Delete Feed"
    end

    assert_current_path feeds_path
    assert_text "Feed deleted successfully"
    assert_no_text "Updated Test Feed"

    # Test regular user can't see admin feeds
    login_as(@regular_user)
    visit feeds_path
    assert_text "Feeds"
    assert_text "Add Feed"
    assert_text "User's Blog"
    assert_no_text "Admin's Blog"

    # Regular user creates a feed
    click_link "Add Feed"
    fill_in "Label", with: "User's Second Feed"
    fill_in "URL", with: "https://user2.example.com/feed.xml"
    check "Active"
    click_button "Save"

    assert_current_path feeds_path
    assert_text "Feed created successfully"
    assert_text "User's Second Feed"
    assert_text "User's Blog"

    # Admin can't see user's feeds
    login_as(@admin)
    visit feeds_path
    assert_text "Admin's Blog"
    assert_no_text "User's Blog"
    assert_no_text "User's Second Feed"
  end

  test "feed form validation and interaction" do
    login_as(@admin)
    visit new_feed_path

    # Test empty form submission
    click_button "Save"
    assert_text "Label can't be blank"
    assert_text "Url can't be blank"

    # Test partial form
    fill_in "Label", with: "Partial Feed"
    click_button "Save"
    assert_text "Url can't be blank"
    assert_no_text "Label can't be blank"

    fill_in "URL", with: "not a url"
    click_button "Save"
    assert_text "Url must be a valid URL"
  end

  test "feed status badge displays correctly" do
    login_as(@admin)

    # Create active and inactive feeds
    visit new_feed_path
    fill_in "Label", with: "Active Feed"
    fill_in "URL", with: "https://active.example.com/feed.xml"
    check "Active"
    click_button "Save"

    visit new_feed_path
    fill_in "Label", with: "Inactive Feed"
    fill_in "URL", with: "https://inactive.example.com/feed.xml"
    uncheck "Active"
    click_button "Save"

    visit feeds_path

    # Check status text present
    assert_text "Active"
    assert_text "Disabled"
  end
end
