class ManuallyPublishesCrosspost
  def publish(crosspost)
    Crosspost.transaction do
      locked_crossposts = Account.where(active: true).find(crosspost.account_id).crossposts.includes(:post).lock
      locked_crosspost = locked_crossposts.find { |cp| cp.id == crosspost.id }
      return Outcome.failure("Crosspost not eligible for manual publish") if locked_crosspost.nil?

      locked_crosspost.update!(
        status: "wip",
        remote_id: nil,
        url: nil,
        attempts: 0,
        failures: [],
        last_attempted_at: nil,
        published_at: nil,
        metadata: {}
      )

      PublishCrosspostJob.perform_later(locked_crosspost.id)
    end
    Outcome.success
  end
end
