class RenewAccessTokensJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :global

  def perform
    Account.where(active: true)
      .find_each do |account|
        if PublishesCrosspost::MatchesPlatformApi.new.match(account)&.renewable?
          RenewsAccessToken.new.renew(account)
        end
      end
  end
end
