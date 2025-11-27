class CheckFeedsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :global

  def perform
    User.includes(:feeds).find_each do |user|
      user.feeds.where(active: true).find_each do |feed|
        FetchFeedJob.perform_later(feed.id)
      end
    end
  end
end
