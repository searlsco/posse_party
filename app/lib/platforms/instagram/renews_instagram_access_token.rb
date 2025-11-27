class Platforms::Instagram
  class RenewsInstagramAccessToken
    def initialize
      @calls_instagram_api = CallsInstagramApi.new
    end

    def renew!(account)
      if account.credentials_renewed_at.nil? || account.credentials_renewed_at < 24.hours.ago
        result = @calls_instagram_api.call(
          method: :get,
          path: "refresh_access_token",
          query: {
            grant_type: "ig_refresh_token",
            access_token: account.credentials["access_token"]
          }
        )
        if result.success? && result.data[:access_token].present?
          account.update!(
            credentials: {"access_token" => result.data[:access_token]},
            credentials_renewed_at: Now.time
          )
          Outcome.success
        else
          Outcome.failure("Failed to renew access token. API message:\n\n#{result.message}")
        end
      else
        Outcome.success
      end
    rescue => e
      Outcome.failure("Failed to renew Instagram token (Error thrown: #{e.message})", e)
    end
  end
end
