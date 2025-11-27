class Platforms::Youtube
  class RefreshesYoutubeAccessToken
    def refresh(account)
      return Outcome.failure("Missing client_id") if account.credentials["client_id"].blank?
      return Outcome.failure("Missing client_secret") if account.credentials["client_secret"].blank?
      return Outcome.failure("Missing refresh_token") if account.credentials["refresh_token"].blank?

      refresh_token(account)
    rescue => e
      Outcome.failure("Exception during token refresh: #{e.message}", e)
    end

    private

    def refresh_token(account)
      response = HTTParty.post(
        "https://oauth2.googleapis.com/token",
        headers: {"Content-Type" => "application/x-www-form-urlencoded"},
        body: {
          client_id: account.credentials["client_id"],
          client_secret: account.credentials["client_secret"],
          refresh_token: account.credentials["refresh_token"],
          grant_type: "refresh_token"
        },
        format: :plain
      )

      if response.success?
        data = RelaxedJson.parse(response)
        account.update!(credentials: account.credentials.merge(
          "access_token" => data[:access_token],
          "access_token_expires_at" => calculate_expires_at(data[:expires_in])
        ))

        Outcome.success
      else
        Outcome.failure("YouTube token refresh failed: #{response.code} - #{response}")
      end
    end

    def calculate_expires_at(expires_in)
      return nil unless expires_in.is_a?(Numeric)

      (Now.time + expires_in.seconds).iso8601
    end
  end
end
