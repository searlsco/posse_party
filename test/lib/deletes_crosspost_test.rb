require "test_helper"

class DeletesCrosspostTest < ActiveSupport::TestCase
  def setup
    @finder = Mocktail.of_next(FindsJobsForCrosspost)
    @subject = DeletesCrosspost.new
    @crosspost = crossposts(:admin_bsky_crosspost)
  end

  def test_deletes_crosspost_when_no_running_jobs
    # Ensure status is not wip to avoid confusion; presence of jobs is authoritative
    @crosspost.update!(status: "ready")

    # Stub job lookup to return none (common in test adapter)
    stubs { @finder.find(@crosspost) }.with { [] }

    outcome = @subject.delete(@crosspost)

    assert outcome.success?, outcome.message
    assert_nil Crosspost.find_by(id: @crosspost.id)
  end

  def test_refuses_when_a_job_is_claimed
    @crosspost.update!(status: "wip")

    fake_job = OpenStruct.new(claimed_execution: Object.new)
    stubs { @finder.find(@crosspost) }.with { [fake_job] }

    outcome = @subject.delete(@crosspost)

    assert outcome.failure?
    assert_not_nil Crosspost.find_by(id: @crosspost.id)
    assert_includes outcome.message, "in progress"
  end
end
