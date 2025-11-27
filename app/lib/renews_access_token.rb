class RenewsAccessToken
  def initialize
    @matches_platform_api = ::PublishesCrosspost::MatchesPlatformApi.new
  end

  def renew(account)
    api = @matches_platform_api.match(account)
    if api.renewable?
      api.renew!(account)
    else
      Outcome.success
    end
  end
end
