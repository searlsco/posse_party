class MarksNextCrosspostAsWipForAccount
  def call(account)
    Crosspost.transaction do
      locked_crossposts = account.crossposts
        .where(status: %w[wip ready])
        .where("crossposts.created_at <= NOW() - INTERVAL '1 second' * ? OR ? = 0", account.crosspost_min_age, account.crosspost_min_age)
        .joins(:post)
        .includes(:post)
        .order("
          posts.remote_published_at asc nulls last,
          posts.remote_updated_at asc nulls last,
          posts.updated_at asc")
        .lock

      if locked_crossposts.none?(&:wip?) && (next_crosspost = locked_crossposts.first)
        next_crosspost.update!(status: "wip")
        PublishCrosspostJob.perform_later(next_crosspost.id)
      end
    end
  end
end
