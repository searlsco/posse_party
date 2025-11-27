require "test_helper"

class ManuallyPublishesCrosspostTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @subject = ManuallyPublishesCrosspost.new
    @crosspost = crossposts(:admin_bsky_crosspost)
  end

  test "resets crosspost to wip status and enqueues publish job" do
    @crosspost.update!(status: "failed", remote_id: "old123", url: "https://old.url",
      attempts: 3, failures: ["error1"], published_at: 1.day.ago)

    assert_enqueued_with(job: PublishCrosspostJob) do
      result = @subject.publish(@crosspost)
      assert result.success?
    end

    @crosspost.reload
    assert_equal "wip", @crosspost.status
    assert_nil @crosspost.remote_id
    assert_nil @crosspost.url
    assert_equal 0, @crosspost.attempts
    assert_empty @crosspost.failures
    assert_nil @crosspost.last_attempted_at
    assert_nil @crosspost.published_at
    assert_empty @crosspost.metadata
  end
end
