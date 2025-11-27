class CreatesMissingCrosspostsForAccount
  def create(account:)
    return Outcome.success unless account.active? && !account.manually_create_crossposts?
    post_ids = posts_missing_crosspost_for(account).pluck(:id)
    return Outcome.success if post_ids.empty?

    Crosspost.transaction do
      Crosspost.insert_all(post_ids.map { |post_id|
        {
          account_id: account.id,
          post_id:,
          status: "skipped"
        }
      })

      Post.where(id: post_ids, crossposts_created_at: nil).update_all(crossposts_created_at: Now.time)
    end

    Outcome.success
  rescue ActiveRecord::RecordInvalid => e
    Outcome.failure("Could not create crossposts: #{e.record.errors.full_messages.to_sentence}", e)
  rescue => e
    Outcome.failure("Could not create crossposts: #{e.message}", e)
  end

  private

  def posts_missing_crosspost_for(account)
    rel = account.user.posts
      .joins(:feed)
      .where(feeds: {automatically_create_crossposts: true})
    rel = rel.where.not(feed_id: account.disabled_feed_ids) if account.disabled_feed_ids.present?
    rel.where <<~SQL, account_id: account.id
      NOT EXISTS (
        SELECT 1 FROM crossposts
        WHERE crossposts.post_id = posts.id
          AND crossposts.account_id = :account_id
      )
    SQL
  end
end
