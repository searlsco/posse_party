require "test_helper"

class ChecksFeedNowTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @url = "https://feed.example.com/atom.xml"
    @feed = @user.feeds.create!(label: "justin.searls.co", url: @url, active: true)

    @xml = Rails.root.join("test/fixtures/files/2025-03-12-justin.searls.co.atom.xml").read
  end

  def test_new_post_count_is_only_for_new_rows
    stub_request(:get, @url).to_return(status: 200, body: @xml, headers: {"Content-Type" => "application/atom+xml"})

    fake_time!(Time.zone.parse("2025-09-27 12:00:00Z")) do
      result = ChecksFeedNow.new.check(feed: @feed, cache: false)
      assert result.success?, result.error
      assert_equal 100, result.data[:new_post_count]
    end

    # Second fetch of identical feed data should report zero new posts
    stub_request(:get, @url).to_return(status: 200, body: @xml, headers: {"Content-Type" => "application/atom+xml"})

    fake_time!(Time.zone.parse("2025-09-27 12:05:00Z")) do
      result = ChecksFeedNow.new.check(feed: @feed, cache: false)
      assert result.success?, result.error
      assert_equal 0, result.data[:new_post_count]
    end
  end
end
