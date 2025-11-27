require "test_helper"

class YoutubeTest < ActiveJob::TestCase
  def test_youtube_short_syndication
    user = New.create(User, email: "user@example.com")
    feed = fake_feed_from(user, "2025-03-12-justin.searls.co.atom.xml")
    user.accounts.find_or_create_by!(platform_tag: "youtube", label: "@testman", credentials: {
      "client_id" => "someclientid",
      "client_secret" => "someclientsecret",
      "refresh_token" => "somerefresh",
      "access_token" => "someaccesstoken"
    })

    FetchesFeed.new.fetch!(feed, cache: false)

    crosspost = Post.find_by(remote_id: "https://justin.searls.co/clips/v30-the-baby-store/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("youtube_clip") do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "qNBigvIZBsw", crosspost.remote_id
    assert_equal "https://www.youtube.com/watch?v=qNBigvIZBsw", crosspost.url
  end
end
