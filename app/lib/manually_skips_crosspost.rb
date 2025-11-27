class ManuallySkipsCrosspost
  def skip(crosspost)
    Crosspost.transaction do
      locked_crossposts = Account.where(active: true).find(crosspost.account_id).crossposts.lock
      locked_crosspost = locked_crossposts.find { |cp| cp.id == crosspost.id }
      return Outcome.failure("Crosspost not eligible to be skipped") if locked_crosspost.nil?

      locked_crosspost.update!(status: "skipped")
    end
    Outcome.success
  end
end
