module Platforms
  class Threads < Base
    TAG = "threads"
    LABEL = "Threads"
    API_BASE_URL = "https://graph.threads.net/v1.0/"

    REQUIRED_CREDENTIALS = %w[access_token].freeze

    POST_CONSTRAINTS = Constants::DEFAULT_POST_CONSTRAINTS.merge(
      character_limit: 500
    ).freeze

    DEFAULT_CROSSPOST_OPTIONS = Platforms::DEFAULT_CROSSPOST_OPTIONS.merge(
      attach_link: true
    ).freeze

    RENEWABLE = true
    IRRELEVANT_CONFIG_OPTIONS = [:append_url_label, :og_image].freeze

    def initialize
      @syndicates_threads_post = SyndicatesThreadsPost.new
      @renews_threads_access_token = RenewsThreadsAccessToken.new
    end

    def setup_docs_available?
      true
    end

    def publish!(crosspost, crosspost_config, crosspost_content)
      @syndicates_threads_post.syndicate!(crosspost, crosspost_config, crosspost_content.string)
    end

    def renew!(account)
      @renews_threads_access_token.renew!(account)
    end
  end
end
