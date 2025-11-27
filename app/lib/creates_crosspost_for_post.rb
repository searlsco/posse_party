class CreatesCrosspostForPost
  DEFAULT_STATUS = "ready"

  def create(user:, post:, account_id:)
    return Result.failure("Select an account") if account_id.blank?

    account = user.accounts.find_by(id: account_id)

    if account.nil?
      Result.failure("Account not found")
    elsif !account.active?
      Result.failure("#{account.notification_label} is inactive")
    elsif post.crossposts.exists?(account_id: account.id)
      Result.failure("A crosspost already exists for #{account.notification_label}")
    else
      created = nil
      Post.transaction do
        created = Crosspost.create!(post: post, account: account, status: DEFAULT_STATUS)
        post.update!(crossposts_created_at: Now.time) if post.crossposts_created_at.blank?
      end
      Result.success(created)
    end
  rescue ActiveRecord::RecordInvalid => e
    Result.failure("Could not create crosspost: #{e.record.errors.full_messages.to_sentence}")
  rescue => e
    Result.failure("Could not create crosspost: #{e.message}")
  end

  def eligible_accounts(user:, post:)
    user.accounts
      .where(active: true)
      .where.not(id: post.crossposts.select(:account_id))
      .order(:platform_tag, :label)
  end
end
