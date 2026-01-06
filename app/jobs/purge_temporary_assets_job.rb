class PurgeTemporaryAssetsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :global

  def perform
    TemporaryAsset.joins(:crosspost).where.not(crossposts: {status: "wip"}).delete_all
  end
end
