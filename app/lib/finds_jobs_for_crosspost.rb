class FindsJobsForCrosspost
  def find(crosspost)
    keys = [
      "#{PublishCrosspostJob.name}/#{crosspost.id}",
      "#{FinishCrosspostJob.name}/#{crosspost.id}"
    ]

    return [] unless defined?(SolidQueue::Job)

    SolidQueue::Job
      .where(concurrency_key: keys)
      .includes(:ready_execution, :claimed_execution, :scheduled_execution, :failed_execution)
      .to_a
  rescue
    []
  end
end
