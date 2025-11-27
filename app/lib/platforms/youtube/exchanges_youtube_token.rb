class Platforms::Youtube
  class ExchangesYoutubeToken
    Result = Struct.new(:success?, :message, :account, :error, keyword_init: true)

    def exchange(authorization_code, state)
      account = find_account_by_state(state)
      return Result.new(success?: false, message: "Invalid state parameter") unless account

      response = make_token_request(account, authorization_code)

      if response.success?
        token_response = RelaxedJson.parse(response)
        if token_response[:refresh_token].present?
          account.update!(
            credentials: account.credentials.merge(
              "access_token" => token_response[:access_token],
              "refresh_token" => token_response[:refresh_token],
              "access_token_expires_at" => token_response[:expires_in]&.then { |exp| (Now.time + exp.seconds).iso8601 },
              "refresh_token_expires_at" => token_response[:refresh_token_expires_in]&.then { |exp| (Now.time + exp.seconds).iso8601 }
            ).except("renewal_oauth_state", "renewal_reminder_sent_at"),
            credentials_renewed_at: Now.time
          )
          Result.new(success?: true, account: account)
        else
          Result.new(
            success?: false,
            message: "YouTube token response missing refresh_token. Response: #{token_response}",
            account: account
          )
        end
      else
        Result.new(
          success?: false,
          message: "YouTube API error: #{response.code} - #{response}",
          account: account
        )
      end
    rescue => e
      Result.new(
        success?: false,
        message: "Exception during token exchange: #{e.message}",
        account: account,
        error: e
      )
    end

    private

    def find_account_by_state(state)
      return nil if state.blank?

      Account.find_by(
        "credentials->>'renewal_oauth_state' = ?", state
      )
    end

    def make_token_request(account, authorization_code)
      HTTParty.post(
        "https://oauth2.googleapis.com/token",
        headers: {
          "Content-Type" => "application/x-www-form-urlencoded"
        },
        body: {
          grant_type: "authorization_code",
          code: authorization_code,
          redirect_uri: Rails.application.routes.url_helpers.credential_renewals_youtube_url,
          client_id: account.credentials["client_id"],
          client_secret: account.credentials["client_secret"]
        },
        format: :plain
      )
    end
  end
end
