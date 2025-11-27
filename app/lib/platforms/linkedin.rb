module Platforms
  class Linkedin < Base
    TAG = "linkedin"
    LABEL = "LinkedIn"
    API_BASE_URL = "https://api.linkedin.com/"

    REQUIRED_CREDENTIALS = %w[client_id access_token client_secret person_urn].freeze

    POST_CONSTRAINTS = Constants::DEFAULT_POST_CONSTRAINTS.merge(
      character_limit: 3000
    ).freeze

    DEFAULT_CROSSPOST_OPTIONS = Platforms::DEFAULT_CROSSPOST_OPTIONS.merge(
      attach_link: true
    ).freeze

    RENEWABLE = true
    RENEWAL_URL_SUPPORTED = true
    IRRELEVANT_CONFIG_OPTIONS = [:append_url_label].freeze

    def initialize
      @syndicates_linkedin_post = SyndicatesLinkedinPost.new
      @potentially_tells_user_to_renew_linkedin_access_token = PotentiallyTellsUserToRenewLinkedinAccessToken.new
    end

    def publish!(crosspost, crosspost_config, crosspost_content)
      @syndicates_linkedin_post.syndicate!(crosspost, crosspost_config, crosspost_content.string)
    end

    def renew!(account)
      @potentially_tells_user_to_renew_linkedin_access_token.potentially_tell(account)
    end

    def renewal_url(account, state)
      oauth_params = {
        response_type: "code",
        client_id: account.credentials["client_id"],
        redirect_uri: Rails.application.routes.url_helpers.credential_renewals_linkedin_url,
        scope: "openid profile w_member_social",
        state: state
      }

      "https://www.linkedin.com/oauth/v2/authorization?#{oauth_params.to_query}"
    end
  end
end
