class RequeueAbandonedWipCrosspostsJob < ApplicationJob
  queue_as :default

  limits_concurrency to: 1, key: :global

  def perform
    Crosspost
      .includes(:account, :post)
      .where(status: "wip")
      .find_each { |crosspost|
        attempt_expired = crosspost.last_attempted_at.present? && Now.time > (crosspost.last_attempted_at + Constants::CROSSPOST_PUBLISH_FINISHING_LIMIT)
        no_active_jobs = jobs_for_crosspost(crosspost).none? { |job| [:ready, :scheduled, :claimed].include?(job.status) }
        stuck_without_job_threshold = Constants::CROSSPOST_PUBLISH_FINISHING_DELAY + Constants::DEFAULT_CROSSPOST_TIMEOUT_DURATION + Constants::CROSSPOST_PUBLISH_FINISHING_LIMIT
        overdue_without_jobs = crosspost.last_attempted_at.present? && Now.time > (crosspost.last_attempted_at + stuck_without_job_threshold)

        if crosspost.published_at.present? || crosspost.remote_id.present? || crosspost.url.present?
          crosspost.update!(status: "published")
          notify_user(crosspost,
            title: "Marked published after stuck WIP",
            severity: "info",
            text: "Crosspost appeared published remotely while still marked WIP here; status corrected.")
        elsif attempt_expired
          if crosspost.attempts >= Constants::DEFAULT_CROSSPOST_MAX_ATTEMPTS
            crosspost.update!(status: "failed", failures: crosspost.failures + [{
              message: "Exceeded finishing window after #{Constants::CROSSPOST_PUBLISH_FINISHING_LIMIT.inspect}",
              time: Now.time
            }])
            notify_user(crosspost,
              title: "Crosspost failed after finishing window",
              severity: "danger",
              text: "Finishing did not complete within the global limit. Attempts exhausted.",
              badge: true)
          else
            PublishCrosspostJob.perform_later(crosspost.id)
            notify_user(crosspost,
              title: "Restarting crosspost after finishing window",
              severity: "warn",
              text: "Finishing exceeded the time limit; retrying from the beginning.")
          end
        elsif no_active_jobs && overdue_without_jobs
          PublishCrosspostJob.perform_later(crosspost.id)
          notify_user(crosspost,
            title: "Re-enqueued stuck crosspost",
            severity: "info",
            text: "Detected no active jobs for this WIP; re-enqueued publish.")
        end
      }
  end

  private

  def notify_user(crosspost, title:, severity:, text:, badge: false)
    refs = [
      {"model" => "Crosspost", "id" => crosspost.id},
      {"model" => "Post", "id" => crosspost.post_id},
      {"model" => "Account", "id" => crosspost.account_id}
    ]
    NotifiesUser.new.notify(user: crosspost.account.user, title: title, severity: severity, text: text, refs: refs, badge: badge)
  end

  def jobs_for_crosspost(crosspost)
    keys = [
      "#{PublishCrosspostJob.name}/#{crosspost.id}",
      "#{FinishCrosspostJob.name}/#{crosspost.id}"
    ]
    SolidQueue::Job.where(concurrency_key: keys)
      .includes(:ready_execution, :claimed_execution, :scheduled_execution, :failed_execution)
  end
end
