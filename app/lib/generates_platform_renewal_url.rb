class GeneratesPlatformRenewalUrl
  def initialize
    @matches_platform_api = PublishesCrosspost::MatchesPlatformApi.new
    @generates_oauth_state = GeneratesOauthState.new
  end

  def generate(account)
    platform = @matches_platform_api.match(account)

    if platform.renewable? && platform.renewal_url_supported?
      state = @generates_oauth_state.generate(account)
      Result.success(platform.renewal_url(account, state))
    else
      Result.failure("Credential renewal unsupported for #{account.platform_label}")
    end
  end
end
