class Platforms::Linkedin
  class RenewsLinkedInTokenFromOAuthCallback
    Result = Struct.new(:success?, :account, :message, keyword_init: true)

    def initialize
      @exchanges_short_lived_linkedin_token = ExchangesShortLivedLinkedinToken.new
    end

    def renew(code:, state:)
      if (account = find_account_by_state(state))
        if (token_result = @exchanges_short_lived_linkedin_token.exchange(account, code)).success?
          Result.new(success?: true, account: account)
        else
          Result.new(success?: false, account: account, message: token_result.message)
        end
      else
        Result.new(success?: false, message: "Invalid state parameter")
      end
    end

    private

    def find_account_by_state(state)
      return if state.blank?
      Account.where("credentials ->> 'renewal_oauth_state' = ?", state).first
    end
  end
end
