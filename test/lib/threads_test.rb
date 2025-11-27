require "test_helper"

class ThreadsTest < ActiveSupport::TestCase
  def test_threads_syndication
    user = New.create(User, email: "user@example.com")
    feed = fake_feed_from(user, "2025-01-28-justin.searls.co.atom.xml")
    user.accounts.find_or_create_by!(platform_tag: "threads", label: "@testman", credentials: {
      access_token: "some_access_token"
    })

    FetchesFeed.new.fetch!(feed, cache: false)

    crosspost = Post.find_by(remote_id: "https://justin.searls.co/takes/2024-10-26-13h47m04s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("threads_take") do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "18063682438777871", crosspost.remote_id
    assert_equal "https://www.threads.net/@wackywavinginflatableflailing/post/DG2_4OAReuQ", crosspost.url
    assert_equal "Look, all I want from political news—literally the only thing I’m asking for, and it isn’t much—is to tell me the literal future exactly as it will unfold so that my brain can go back to focusing on anything else.", crosspost.content

    # Post a Shot post
    crosspost = Post.find_by(remote_id: "https://justin.searls.co/shots/2024-10-28-09h56m20s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("threads_shot") do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "17990266949795149", crosspost.remote_id
    assert_equal "https://www.threads.net/@wackywavinginflatableflailing/post/DG3dlMLxZxS", crosspost.url
    assert_equal "Orlando, I love you 🎶", crosspost.content
  end
end
