require "test_helper"

class FacebookTest < ActiveSupport::TestCase
  def test_facebook_syndication
    user = New.create(User, email: "user@example.com")
    feed = fake_feed_from(user, "2025-06-18-justin.searls.co.atom.xml")
    user.accounts.find_or_create_by!(platform_tag: "facebook", label: "Test Page", credentials: {
      page_id: "somepageid",
      page_access_token: "someaccesstoken"
    })

    FetchesFeed.new.fetch!(feed, cache: false)

    crosspost = Post.find_by(remote_id: "https://justin.searls.co/takes/2025-06-16-21h31m25s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("facebook_take") do
      PublishesCrosspost.new.publish(crosspost.id)
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "122196970568094094", crosspost.remote_id
    assert_equal "https://www.facebook.com/somepageid/posts/122196970568094094", crosspost.url
    assert_equal "Similar to Kojima, I had to adjust the runtime and prevalence of swears in the Breaking Change podcast because they weren't pissing enough people off https://www.videogameschronicle.com/news/composer-says-kojima-changed-death-stranding-2-because-it-wasnt-polarizing-enough/", crosspost.content
  end
end
