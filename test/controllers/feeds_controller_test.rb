require "test_helper"

class FeedsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    login_as(@admin)
  end

  def test_create_feed_reports_zero_posts
    stub_request(:get, /zero-feed\.example\.com\/feed\.xml/)
      .to_return(status: 200, body: <<~XML, headers: {"Content-Type" => "application/xml"})
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>Zero Feed</title>
          <updated>#{Time.current.iso8601}</updated>
        </feed>
      XML

    post feeds_path, params: {feed: {label: "Zero Feed", url: "https://zero-feed.example.com/feed.xml", active: true}}
    assert_response :found
    follow_redirect!

    assert_equal feeds_path, path
    assert_includes response.body, "Feed created successfully. Found 0 new posts."
  end

  def test_create_feed_reports_check_failure
    stub_request(:get, /bad-feed\.example\.com\/feed\.xml/).to_raise(SocketError.new("mock network down"))

    post feeds_path, params: {feed: {label: "Bad Feed", url: "https://bad-feed.example.com/feed.xml", active: true}}
    assert_response :found
    follow_redirect!

    assert_equal feeds_path, path
    assert_includes response.body, "Feed created successfully, but checking the feed failed: Connection failed: mock network down"
  end

  def test_check_action_reports_counts
    feed = @admin.feeds.create!(label: "Counted Feed", url: "https://ok.example.com/feed.xml", active: true)

    # Return a single-entry Atom feed for the check
    stub_request(:get, /ok\.example\.com\/feed\.xml/)
      .to_return(status: 200, body: <<~XML, headers: {"Content-Type" => "application/xml"})
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>OK Feed</title>
          <updated>#{Time.current.iso8601}</updated>
          <entry>
            <title>One</title>
            <link href="https://ok.example.com/1" />
            <id>https://ok.example.com/1</id>
            <updated>#{Time.current.iso8601}</updated>
            <content type="html">Body</content>
          </entry>
        </feed>
      XML

    patch check_feed_path(feed)
    assert_response :found
    follow_redirect!

    assert_equal edit_feed_path(feed), path
    assert_includes response.body, "Found 1 new post."
  end
end
