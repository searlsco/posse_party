class HandlesJobError
  def initialize
    @notifies_admins = NotifiesAdmins.new(logger: SolidQueue.logger)
  end

  def call(job, error)
    refs = build_refs(job)
    subject = "POSSE Party Error: #{error&.message&.to_s&.truncate(60)}"
    body = <<~MSG
      { error_class: #{job.class.name}, args: #{job.arguments.inspect}, scheduled_at: #{job.scheduled_at}, job_id: #{job.job_id} }

      #{error.class}: #{error.message}
      #{error.backtrace&.join("\n")}
    MSG
    @notifies_admins.call(subject: subject, body: body, severity: "danger", badge: true, refs: refs)
    raise error
  end

  private

  def build_refs(job)
    case job.class
    when PublishCrosspostJob, FinishCrosspostJob
      crosspost_id = job.arguments&.first
      crosspost_id ? [{"model" => "Crosspost", "id" => crosspost_id}] : []
    when FetchFeedJob
      feed_id = job.arguments&.first
      feed_id ? [{"model" => "Feed", "id" => feed_id}] : []
    else
      []
    end
  end
end
