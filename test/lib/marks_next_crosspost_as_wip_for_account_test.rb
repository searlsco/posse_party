require "test_helper"

class MarksNextCrosspostAsWipForAccountTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    user = users(:user)
    @feed = fake_feed_from(user, "2025-01-28-justin.searls.co.atom.xml")
    @account = user.accounts.find_or_create_by!(platform_tag: "bsky", label: "Test Account", credentials: {
      email: "user@example.com",
      password: "password"
    })
    @post = @feed.posts.create!(url: "http://example.com", remote_id: "1", remote_published_at: 1.day.ago)
  end

  def test_sets_next_crosspost_to_wip_and_enqueues_job_transactionally
    crosspost = Crosspost.create!(account: @account, post: @post, status: "ready")
    assert_changes -> { crosspost.reload.status }, from: "ready", to: "wip" do
      assert_enqueued_with(job: PublishCrosspostJob, args: [crosspost.id]) do
        MarksNextCrosspostAsWipForAccount.new.call(@account)
      end
    end
  end

  def test_does_nothing_if_a_wip_crosspost_exists
    Crosspost.create!(account: @account, post: @post, status: "wip")
    assert_no_enqueued_jobs do
      MarksNextCrosspostAsWipForAccount.new.call(@account)
    end
  end

  def test_does_nothing_if_no_ready_crossposts
    assert_no_enqueued_jobs do
      MarksNextCrosspostAsWipForAccount.new.call(@account)
    end
  end

  def test_does_nothing_if_crosspost_is_too_new_based_on_min_age
    @account.update!(crosspost_min_age: 10)
    Crosspost.create!(account: @account, post: @post, status: "ready")

    assert_no_enqueued_jobs do
      MarksNextCrosspostAsWipForAccount.new.call(@account)
    end
  end
end
