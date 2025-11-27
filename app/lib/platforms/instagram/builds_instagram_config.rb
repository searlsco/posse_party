class Platforms::Instagram
  Config = Struct.new(:app_id, :app_secret, :user_id, :access_token, :access_token_refreshed_at, keyword_init: true)

  class BuildsInstagramConfig
    def build(account)
      creds = account.credentials
      user_id = creds["user_id"].presence
      if user_id && creds["access_token"].present?
        Platforms::Instagram::Config.new(
          app_id: creds["app_id"],
          app_secret: creds["app_secret"],
          user_id: user_id,
          access_token: creds["access_token"],
          access_token_refreshed_at: account.credentials_renewed_at
        )
      end
    end
  end
end
