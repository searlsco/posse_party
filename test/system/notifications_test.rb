require "application_system_test_case"

class NotificationsTest < ApplicationSystemTestCase
  def setup
    @user = users(:user)
    login_as(@user)

    stub_request(:get, /acceptance\.example\.com\/feed\.xml/)
      .to_return(status: 200, body: <<~XML, headers: {"Content-Type" => "application/xml"})
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>Acceptance Feed</title>
          <link href="https://acceptance.example.com/" />
          <updated>#{Time.current.iso8601}</updated>
          <entry>
            <title>Acceptance Post</title>
            <link href="https://acceptance.example.com/post/1" />
            <id>https://acceptance.example.com/post/1</id>
            <updated>#{Time.current.iso8601}</updated>
            <content type="html">Acceptance content</content>
          </entry>
        </feed>
      XML

    @account = Account.create!(
      user: @user,
      platform_tag: "test",
      active: true,
      label: "Test Platform",
      credentials: {}
    )

    @fail_account_a = Account.create!(
      user: @user,
      platform_tag: "test_failure",
      active: true,
      label: "Fail A",
      credentials: {}
    )
    @fail_account_b = Account.create!(
      user: @user,
      platform_tag: "test_failure",
      active: true,
      label: "Fail B",
      credentials: {}
    )

    @skip_account = Account.create!(
      user: @user,
      platform_tag: "test_skipped",
      active: true,
      label: "Skip",
      credentials: {}
    )
  end

  test "manage shows Skip publish for ready and marks skipped" do
    # Arrange
    post = New.create(Post, feed: New.create(Feed, user: @user), title: "Ready to skip")
    account = New.create(Account, user: @user, platform_tag: "test", label: "@ready", active: true)
    crosspost = New.create(Crosspost, post: post, account: account, status: "ready")

    # Act
    visit crosspost_path(crosspost)
    click_on "Skip publish"

    # Assert
    assert_text "Crosspost skipped"
    assert_text "Skipped"
    assert_no_text "Skip publish"
  end

  test "manage hides Skip publish when not eligible" do
    # Arrange
    feed = New.create(Feed, user: @user)
    post = New.create(Post, feed: feed, title: "Various states")
    account_wip = New.create(Account, user: @user, platform_tag: "test", label: "@wip", active: true)
    account_published = New.create(Account, user: @user, platform_tag: "test", label: "@published", active: true)
    account_skipped = New.create(Account, user: @user, platform_tag: "test", label: "@skipped", active: true)

    wip_cp = New.create(Crosspost, post: post, account: account_wip, status: "wip")
    published_cp = New.create(Crosspost, post: post, account: account_published, status: "published")
    skipped_cp = New.create(Crosspost, post: post, account: account_skipped, status: "skipped")

    # Act & Assert (wip)
    visit crosspost_path(wip_cp)
    assert_no_text "Skip publish"

    # Act & Assert (published)
    visit crosspost_path(published_cp)
    assert_no_text "Skip publish"

    # Act & Assert (skipped)
    visit crosspost_path(skipped_cp)
    assert_no_text "Skip publish"
  end
  test "end-to-end logs from feed fetch and publish (success)" do
    visit new_feed_path
    fill_in "Label", with: "Acceptance Feed"
    fill_in "URL", with: "https://acceptance.example.com/feed.xml"
    check "Active"
    click_button "Save"
    assert_text "Feed created successfully"

    feed = Feed.find_by(label: "Acceptance Feed")
    visit edit_feed_path(feed)
    click_link "Check Feed"
    assert_text "Found 0 new posts."
    feed.reload
    assert_equal 1, feed.posts.count

    visit edit_account_path(@account)
    fill_in "Label", with: "Test Platform Updated"
    click_button "Save"
    assert_text "Account updated successfully"

    visit logs_path
    assert_selector "h1", text: "Logs"
    assert_text "Test updated"
    click_on "Test updated", match: :first
    visit logs_path
    click_on "Mark all as seen"
    feed.reload
    fail_crosspost = feed.crossposts.where(account_id: @fail_account_a.id).first

    visit crosspost_path(fail_crosspost)
    click_on "Trigger publish"
    assert_text "Crosspost (re)publish requested"
    perform_last_job(expect_error: true, arguments: [fail_crosspost.id])
    visit current_path
    assert_text "Failure History"
    visit logs_path
    assert_text "Publishing \"Acceptance Post\" to Test Failure"

    crosspost = feed.crossposts.where(account_id: @account.id).first
    visit crosspost_path(crosspost)
    click_on "Trigger publish"
    assert_text "Crosspost (re)publish requested"
    perform_last_job(arguments: [crosspost.id])
    visit logs_path
    assert_text "Published \"Acceptance Post\" to Test"
    click_on "Mark all as seen"
  end

  test "end-to-end logs when publish is skipped" do
    visit new_feed_path
    fill_in "Label", with: "Acceptance Feed"
    fill_in "URL", with: "https://acceptance.example.com/feed.xml"
    check "Active"
    click_button "Save"
    assert_text "Feed created successfully"

    feed = Feed.find_by(label: "Acceptance Feed")
    visit edit_feed_path(feed)
    click_link "Check Feed"
    assert_text "Found 0 new posts."

    skip_crosspost = feed.crossposts.find_by!(account_id: @skip_account.id)

    visit crosspost_path(skip_crosspost)
    click_on "Trigger publish"
    assert_text "Crosspost (re)publish requested"
    perform_last_job(arguments: [skip_crosspost.id])

    visit logs_path
    assert_text "Skipped publishing \"Acceptance Post\" to Test Skipped"

    within find("#logs-grid a", text: "Skipped publishing \"Acceptance Post\" to Test Skipped") do
      assert_selector "svg.text-warn"
    end

    click_on "Skipped publishing \"Acceptance Post\" to Test Skipped"
    assert_text "Crosspost skipped"
  end
end

private

def perform_last_job(expect_error: false, job_class: PublishCrosspostJob, arguments: nil, timeout: 2.0)
  adapter = ActiveJob::Base.queue_adapter
  job = nil
  deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
  until job || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
    job = adapter.enqueued_jobs.reverse.find { |j|
      j[:job] == job_class && (arguments.nil? || j[:args] == arguments)
    }
  end
  raise "#{job_class} not enqueued" unless job
  adapter.enqueued_jobs.delete(job)
  if expect_error
    assert_difference -> { Notification.where(severity: "danger").count }, 1 do
      job_class.perform_now(*job[:args])
    end
  else
    job_class.perform_now(*job[:args])
  end
end
