class FetchFeedJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(feed_id) { feed_id }

  def perform(feed_id)
    FetchesFeed.new.fetch!(Feed.includes(:user).find_by(id: feed_id))
  end
end
