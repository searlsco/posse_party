require "application_system_test_case"

class AccountOverridesConfigTest < ApplicationSystemTestCase
  def test_overrides_ui_and_configuration_displays
    user = users(:user)
    login_as(user)

    visit new_account_path

    select "Bluesky", from: "Platform"
    assert_text "Credentials for Bluesky"
    assert_text "Configuration Overrides"
    assert_field "Format String"
    assert_text "Credentials for Bluesky"
    assert_text "Configuration Overrides"

    assert_selector "[rel='format_string_default']", text: /Default:.*\{\{title\}\}/
    assert_selector "[rel='append_url_spacer_default']", text: /Default:/
    assert_selector "[rel='append_url_label_default']", text: /Default:.*🔗/
    assert_selector "[rel='truncate_default']", text: /Default:.*true/i
    assert_selector "[rel='append_url_default']", text: /Default:.*false/i

    # Persistence: entering an override value should persist across platform switch
    fill_in "Format String", with: "FMT"
    select "LinkedIn", from: "Platform"
    assert_text "Credentials for LinkedIn"
    assert_field "Format String", with: "FMT"
    # Switch back to Bluesky to continue with credentials used below
    select "Bluesky", from: "Platform"
    assert_text "Credentials for Bluesky"
    # Clear the temporary value so overrides remain unspecified for this flow
    fill_in "Format String", with: ""

    # Tri-state selects include Not specified with default in label
    within find_field("Truncate Content") do
      assert_selector "option", text: "-- Default --"
    end
    within find_field("Always Append URL") do
      assert_selector "option", text: "-- Default --"
    end

    fill_in "Label", with: "Bsky Test"
    check "Active"

    fill_in "Email", with: "test@example.com"
    fill_in "Password", with: "secret"

    # Leave overrides unspecified; set only og_image to ensure string nil/blank logic works
    fill_in "OpenGraph Image URL", with: ""

    click_on "Create Account"
    assert_text "Account created successfully"

    acct = Account.find_by(label: "Bsky Test")

    # Add a feed with a posse:post override JSON
    stubbed_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>User Feed</title>
        <updated>#{Time.current.iso8601}</updated>
        <entry>
          <title>Override Demo</title>
          <link href="https://example.com/posts/1" />
          <id>https://example.com/posts/1</id>
          <updated>#{Time.current.iso8601}</updated>
          <content type="html">Body</content>
          <posse:post format="json"><![CDATA[{"append_url":true,"append_url_spacer":" ","append_url_label":"🔗","platform_overrides":{"bsky":{"attach_link":true}},"format_string":"{{title}}"}]]></posse:post>
        </entry>
      </feed>
    XML

    stub_request(:get, /ui-config-test\.example\.com\/feed\.xml/)
      .to_return(status: 200, body: stubbed_xml, headers: {"Content-Type" => "application/xml"})

    visit new_feed_path
    fill_in "Label", with: "UI Config Test"
    fill_in "URL", with: "https://ui-config-test.example.com/feed.xml"
    check "Active"
    click_button "Save"
    assert_text "Feed created successfully"

    # Associate account to feed by creating a crosspost via check
    feed = Feed.find_by(label: "UI Config Test")
    visit edit_feed_path(feed)
    click_link "Check Feed"
    assert_text "Found 0 new posts."

    # Open the created post
    visit posts_path
    assert_text "Override Demo"
    click_link "Override Demo"

    # Post Configuration form values (all disabled) — representative checks
    assert_field "Format String", with: "{{title}}", disabled: true
    assert_equal "true", find_field("Always Append URL", disabled: true).value
    find_field "OpenGraph Image URL", disabled: true

    # Open the Bluesky crosspost (label supports URL label)
    cp = Crosspost.joins(:post, :account).find_by(posts: {title: "Override Demo"}, accounts: {platform_tag: "bsky"})
    visit crosspost_path(cp)
    assert_selector "h2", text: "Post × Account"
    assert_selector "a[href='#{post_path(cp.post)}']"
    assert_selector "a[href='#{edit_account_path(cp.account)}']"
    assert_selector "h2", text: "Configuration Overrides"
    within(".grid.lg\\:grid-cols-2", match: :first) do
      assert_no_text "Leave blank or select \"-- Default --\""
    end
    # Crosspost Configuration form values (munged) — representative checks
    assert_field "Format String", with: "{{title}}", disabled: true
    assert_equal "true", find_field("Truncate Content", disabled: true).value
    assert_equal "true", find_field("Always Append URL", disabled: true).value
    find_field "OpenGraph Image URL", disabled: true
    assert_selector "[rel='format_string_default']", text: /From:\s*Post override/

    visit edit_account_path(acct)
    select "False", from: "Truncate Content"
    select "True", from: "Append URL If Truncated"
    fill_in "OpenGraph Image URL", with: "https://example.com/og.png"
    click_on "Save Account"
    assert_text "Account updated successfully"

    acct.reload
    assert_equal false, acct.truncate
    assert_equal true, acct.append_url_if_truncated
    assert_equal "https://example.com/og.png", acct.og_image
    assert_nil acct.format_string
    assert_nil acct.append_url
    assert_nil acct.append_url_spacer
    assert_nil acct.append_url_label
    assert_nil acct.attach_link

    visit post_path(Post.find_by(title: "Override Demo"))
    # Representative defaults at Post-level remain unspecified
    assert_equal "", find_field("Truncate Content", disabled: true).value

    visit crosspost_path(cp)
    assert_equal "false", find_field("Truncate Content", disabled: true).value
    assert_equal "true", find_field("Always Append URL", disabled: true).value
    assert_field "OpenGraph Image URL", with: "https://example.com/og.png", disabled: true
    assert_selector "[rel='truncate_default']", text: /From:\s*Account override/

    visit new_account_path
    select "Bluesky", from: "Platform"
    assert_text "Configuration Overrides"
    fill_in "Label", with: "Switch Test"
    check "Active"
    fill_in "Email", with: "t2@example.com"
    fill_in "Password", with: "secret2"
    fill_in "Format String", with: "FS"
    fill_in "Appended URL Label", with: "LNK"
    fill_in "OpenGraph Image URL", with: "https://img.example.com/a.png"
    select "Threads", from: "Platform"
    assert_text "Credentials for Threads"
    assert_no_text "Appended URL Label"
    assert_no_text "OpenGraph Image URL"
    fill_in "account_credentials_access_token", with: "token-1"
    click_on "Create Account"
    assert_text "Account created successfully"

    threads_acct = Account.find_by(label: "Switch Test")
    assert_equal "threads", threads_acct.platform_tag
    assert_nil threads_acct.append_url_label
    assert_nil threads_acct.og_image
  end

  def test_user_can_clear_account_overrides_to_default
    admin = users(:admin)
    login_as(admin)

    account = accounts(:admin_bsky_account)

    visit edit_account_path(account)
    select "True", from: "Truncate Content"
    fill_in "Appended URL Label", with: "Link"
    fill_in "Spacer Before Appended URL", with: "L "
    click_on "Save Account"
    assert_text "Account updated successfully"

    account.reload
    assert_equal true, account.truncate
    assert_equal "Link", account.append_url_label
    assert_equal "L ", account.append_url_spacer

    visit edit_account_path(account)
    select "-- Default --", from: "Truncate Content"
    fill_in "Appended URL Label", with: ""
    fill_in "Spacer Before Appended URL", with: ""
    click_on "Save Account"
    assert_text "Account updated successfully"

    account.reload
    assert_nil account.truncate
    assert_nil account.append_url_label
    assert_nil account.append_url_spacer
  end
end
