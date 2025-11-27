class ValidatesAccountCredentials
  def initialize
    @matches_platform_api = PublishesCrosspost::MatchesPlatformApi.new
  end

  def validate(account)
    platform_api = @matches_platform_api.match(account)
    required_credentials = platform_api.required_credentials
    missing_credentials = required_credentials.reject { |key| account.credentials.key?(key) }
    blank_credentials = required_credentials.select { |key| account.credentials[key].blank? }

    if missing_credentials.any?
      Outcome.failure("Missing required credentials: #{missing_credentials.join(", ")}")
    elsif blank_credentials.any?
      Outcome.failure("#{account.platform_label} requires credential fields: #{blank_credentials.join(", ")}")
    else
      Outcome.success
    end
  end
end
