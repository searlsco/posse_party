require "test_helper"

class XTest < ActiveSupport::TestCase
  def test_x_syndication
    user = New.create(User, email: "user@example.com")
    feed = fake_feed_from(user, "2025-01-28-justin.searls.co.atom.xml")
    user.accounts.find_or_create_by!(platform_tag: "x", label: "@testman", credentials: {
      api_key: "some_api_key",
      api_key_secret: "some_api_secret",
      access_token: "some_access_token",
      access_token_secret: "some_access_token_secret"
    })

    FetchesFeed.new.fetch!(feed, cache: false)

    crosspost = Post.find_by(remote_id: "https://justin.searls.co/takes/2024-10-26-13h47m04s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("x_take", except: [:headers]) do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "1886036391227732147", crosspost.remote_id
    assert_equal "https://x.com/searls/status/1886036391227732147", crosspost.url
    assert_equal "Look, all I want from political news—literally the only thing I’m asking for, and it isn’t much—is to tell me the literal future exactly as it will unfold so that my brain can go back to focusing on anything else.", crosspost.content

    # Post a Shot post
    crosspost = Post.find_by(remote_id: "https://justin.searls.co/shots/2024-10-28-09h56m20s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("x_shot", except: [:headers]) do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "1886039359113077138", crosspost.remote_id
    assert_equal "https://x.com/searls/status/1886039359113077138", crosspost.url
    assert_equal "Orlando, I love you 🎶 https://justin.searls.co/shots/2024-10-28-09h56m20s/", crosspost.content
  end
end
