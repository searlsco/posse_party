class GeneratesOauthState
  def generate(account)
    SecureRandom.hex(16).tap do |state|
      account.update!(
        credentials: account.credentials.merge("renewal_oauth_state" => state)
      )
    end
  end
end
