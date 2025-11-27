require "test_helper"

class CrosspostsControllerTest < ActionDispatch::IntegrationTest
  def test_destroy_deletes_and_redirects
    user = users(:admin) # owns the admin_* fixtures
    login_as(user)

    crosspost = crossposts(:admin_bsky_crosspost)
    post = crosspost.post

    delete crosspost_path(crosspost)

    assert_redirected_to post_path(post)
    assert_equal "Crosspost deleted successfully.", flash[:notice]
    assert_nil Crosspost.find_by(id: crosspost.id)
  end

  def test_destroy_refuses_when_job_is_claimed
    user = users(:admin)
    login_as(user)

    crosspost = crossposts(:admin_bsky_crosspost)

    job = SolidQueue::Job.create!(
      queue_name: "default",
      class_name: PublishCrosspostJob.name,
      arguments: [].to_yaml,
      concurrency_key: "#{PublishCrosspostJob.name}/#{crosspost.id}"
    )
    process = SolidQueue::Process.create!(
      kind: "worker",
      last_heartbeat_at: Now.time,
      pid: 12345,
      name: "test-worker"
    )
    SolidQueue::ClaimedExecution.create!(job: job, process: process)

    delete crosspost_path(crosspost)

    assert_redirected_to crosspost_path(crosspost)
    assert_equal "Cannot delete crosspost while a job is in progress. Please wait and try again.", flash[:alert]
    assert_not_nil Crosspost.find_by(id: crosspost.id)
  end
end
