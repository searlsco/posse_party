class PublishCrosspostJob < ApplicationJob
  queue_as :default

  limits_concurrency to: 1, key: ->(crosspost_id) { crosspost_id }

  def perform(crosspost_id)
    Timeout.timeout(Constants::DEFAULT_CROSSPOST_TIMEOUT_DURATION) do
      PublishesCrosspost.new.publish(crosspost_id)
    end
  end
end
