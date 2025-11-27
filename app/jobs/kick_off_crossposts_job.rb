class KickOffCrosspostsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :global

  def perform
    Account
      .joins(:user)
      .where(active: true)
      .where(users: {allow_automatic_syndication: true})
      .where(manually_publish_crossposts: false)
      .where("EXISTS (SELECT 1 FROM crossposts WHERE crossposts.account_id = accounts.id AND crossposts.status = 'ready' AND crossposts.created_at <= NOW() - INTERVAL '1 second' * accounts.crosspost_min_age)")
      .where("NOT EXISTS (SELECT 1 FROM crossposts WHERE crossposts.account_id = accounts.id AND (crossposts.status = 'wip' OR crossposts.published_at > NOW() - INTERVAL '1 second' * accounts.crosspost_cooldown))")
      .find_each do |account|
        MarksNextCrosspostAsWipForAccount.new.call(account)
      end
  end
end
