class DeletesCrosspost
  def initialize
    @finds_jobs_for_crosspost = FindsJobsForCrosspost.new
  end

  def delete(crosspost)
    Crosspost.transaction do
      locked = Crosspost.lock.find(crosspost.id)
      active_jobs = @finds_jobs_for_crosspost.find(locked)

      if active_jobs.any? { |job| job.claimed_execution.present? }
        return Outcome.failure("Cannot delete crosspost while a job is in progress. Please wait and try again.")
      elsif active_jobs.select { |job| job.ready_execution.present? || job.scheduled_execution.present? }.all?(&:destroy) &&
          locked.destroy
        Outcome.success("Crosspost deleted successfully.")
      else
        errors = active_jobs.flat_map { |j| j.errors.full_messages.presence || [] } + (locked.errors.full_messages.presence || [])
        Outcome.failure("Failed to delete crosspost: #{errors.to_sentence}")
      end
    end
  end
end
