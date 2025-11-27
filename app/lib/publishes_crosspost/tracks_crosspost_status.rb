class PublishesCrosspost
  class TracksCrosspostStatus
    def track(crosspost, &actor)
      result = attempt_action!(actor)

      if result.success? && crosspost.published?
        notify_user(crosspost,
          title: "Published #{crosspost.post.notification_label} to #{crosspost.account.notification_label}",
          severity: "success",
          text: "Crosspost published to: #{crosspost.url}")
        result
      elsif result.success? && crosspost.skipped?
        notify_user(crosspost,
          title: "Skipped publishing #{crosspost.post.notification_label} to #{crosspost.account.notification_label}",
          severity: "warn",
          text: "Crosspost skipped")
        result
      elsif should_finish_later?(result, crosspost)
        FinishCrosspostJob.set(wait: Constants::CROSSPOST_PUBLISH_FINISHING_DELAY).perform_later(crosspost.id)

        notify_user(crosspost,
          title: "Queued #{crosspost.post.notification_label} to #{crosspost.account.notification_label} to finish processing",
          severity: "info",
          text: "Crosspost queued to be finished later (e.g. waiting on videos to upload)")
        result
      else
        record_failure_and_notify(crosspost, result)
        PublishCrosspostJob.perform_later(crosspost.id) if crosspost.wip?
      end
    end

    private

    def attempt_action!(actor)
      result = begin
        actor.call
      rescue UnretriableError => e
        Result.new(success?: false, unretriable?: true, message: "Syndication failed and should not be retried", error: e)
      rescue => e
        Result.new(success?: false, message: "Failed to publish crosspost", error: e)
      end

      result || Result.new(success?: false, message: "Publication returned an invalid status")
    end

    def should_finish_later?(result, crosspost)
      result.success? && result.needs_to_finish? &&
        crosspost.last_attempted_at.present? &&
        Now.time < (crosspost.last_attempted_at + Constants::CROSSPOST_PUBLISH_FINISHING_LIMIT)
    end

    def record_failure_and_notify(crosspost, result, action_description: "Publishing")
      crosspost.update!({
        failures: crosspost.failures + [{
          message: result.message,
          cause: result.error&.message,
          backtrace: result.error&.backtrace,
          time: Now.time
        }],
        status: ("failed" if crosspost.attempts >= Constants::DEFAULT_CROSSPOST_MAX_ATTEMPTS || result.unretriable?)
      }.compact)

      notify_user(crosspost,
        title: "#{action_description} #{crosspost.post.notification_label} to #{crosspost.account.notification_label} failed",
        severity: "danger",
        text: [result.message, result.error&.message, result.error&.backtrace&.join("\n")].compact.join("\n\n").presence || "Unknown failure",
        badge: true)
    end

    def notify_user(crosspost, title:, severity:, text:, badge: false)
      refs = [
        {"model" => "Crosspost", "id" => crosspost.id},
        {"model" => "Post", "id" => crosspost.post_id},
        {"model" => "Account", "id" => crosspost.account_id}
      ]
      NotifiesUser.new.notify(user: crosspost.account.user, title: title, severity: severity, text: text, refs: refs, badge: badge)
    end
  end
end
