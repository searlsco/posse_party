class Platforms::Linkedin
  class ExchangesShortLivedLinkedinToken
    def exchange(account, authorization_code)
      response = make_token_request(account, authorization_code)

      if response.success?
        update_account_credentials(account, response.parsed_response)
        Outcome.success
      else
        Outcome.failure("LinkedIn API error: #{response.code} - #{response.body}")
      end
    rescue => e
      Outcome.failure("Exception during token exchange: #{e.message}", e)
    end

    private

    def make_token_request(account, authorization_code)
      callback_url = Rails.application.routes.url_helpers.credential_renewals_linkedin_url

      HTTParty.post(
        "https://www.linkedin.com/oauth/v2/accessToken",
        headers: {
          "Content-Type" => "application/x-www-form-urlencoded"
        },
        body: {
          grant_type: "authorization_code",
          code: authorization_code,
          redirect_uri: callback_url,
          client_id: account.credentials["client_id"],
          client_secret: account.credentials["client_secret"]
        }
      )
    end

    def update_account_credentials(account, token_response)
      account.update!(
        credentials: account.credentials.merge(
          "access_token" => token_response["access_token"],
          "expires_at" => calculate_expires_at(token_response["expires_in"])
        ).except("renewal_oauth_state", "renewal_reminder_sent_at"),
        credentials_renewed_at: Now.time
      )
    end

    def calculate_expires_at(expires_in)
      return nil unless expires_in.is_a?(Numeric)

      Now.from_now(expires_in.seconds).iso8601
    end
  end
end
