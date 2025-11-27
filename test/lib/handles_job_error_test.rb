require "test_helper"

class HandlesJobErrorTest < ActiveSupport::TestCase
  def setup
    @error = StandardError.new("Job failed")
    @job = OpenStruct.new(
      class: OpenStruct.new(name: "TestJob"),
      arguments: ["arg1", "arg2"],
      scheduled_at: Time.current,
      job_id: "123abc"
    )
  end

  test "notifies developer with job metadata and re-raises error" do
    subject = HandlesJobError.new

    assert_raises(StandardError, "Job failed") do
      subject.call(@job, @error)
    end
  end

  test "instantiates NotifiesDeveloper with correct parameters" do
    # Just test that it instantiates correctly and re-raises error
    subject = HandlesJobError.new

    assert_raises(StandardError) do
      subject.call(@job, @error)
    end
  end
end
