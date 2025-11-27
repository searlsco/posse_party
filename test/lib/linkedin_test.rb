require "test_helper"

class LinkedinTest < ActiveSupport::TestCase
  def test_linkedin_syndication
    user = New.create(User, email: "user@example.com")
    feed = fake_feed_from(user, "2025-06-18-justin.searls.co.atom.xml")
    user.accounts.find_or_create_by!(platform_tag: "linkedin", label: "Test Page", credentials: {
      client_id: "someclientid",
      client_secret: "someclientsecret",
      access_token: "sometoken",
      person_urn: "urn:li:person:someperson"
    })

    FetchesFeed.new.fetch!(feed, cache: false)

    crosspost = Post.find_by(remote_id: "https://justin.searls.co/takes/2025-06-14-09h51m32s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("linkedin_take") do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "urn:li:share:7341301993115684864", crosspost.remote_id
    assert_equal "https://www.linkedin.com/feed/update/urn:li:share:7341301993115684864/", crosspost.url
    assert_equal "Been a fun couple of weeks touring more remote parts of Japan, and I'm happy to report I've now stayed at least one night in 46 of Japan's 47 prefectures. I'm saving the last—Hokkaido—for next year. RubyKaigiかな", crosspost.content
  end

  def test_linkedin_parentheses_escaping
    user = New.create(User, email: "user@example.com")
    feed = fake_feed_from(user, "2025-07-08-justin.searls.co.atom.xml")

    # Using fake credentials for committed version
    user.accounts.find_or_create_by!(platform_tag: "linkedin", label: "Test Account", credentials: {
      client_id: "fakeclientid",
      expires_at: "2099-09-01T12:50:18Z",
      person_urn: "urn:li:person:fakepersonurn",
      access_token: "fakeaccesstoken",
      client_secret: "fakeclientsecret"
    })

    FetchesFeed.new.fetch!(feed, cache: false)

    # Get the post with parentheses in content
    crosspost = Post.find_by(remote_id: "https://justin.searls.co/takes/2025-07-06-17h23m32s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("linkedin_parentheses_fix") do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    # Assertions based on the observed results
    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "urn:li:share:7348349577130860544", crosspost.remote_id
    assert_equal "https://www.linkedin.com/feed/update/urn:li:share:7348349577130860544/", crosspost.url

    # The key assertion: verify the content with parentheses was saved correctly
    assert_equal "Anybody else have a recent MacBook Pro (M4 Pro in my case) for which the keyboard suddenly became really squeaky? Every time I hit the space bar, it's like nails on a chalkboard.", crosspost.content
  end
end
