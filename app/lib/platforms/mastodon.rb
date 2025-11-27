module Platforms
  class Mastodon < Base
    TAG = "mastodon"
    LABEL = "Mastodon"

    REQUIRED_CREDENTIALS = %w[base_url access_token].freeze

    POST_CONSTRAINTS = Constants::DEFAULT_POST_CONSTRAINTS.merge(
      character_limit: 500,
      counter: CountsToot.new
      # This is not actually accurate b/c Mastodon only counts if a https? protocol is present and our pattern is optional, but the pattern ranges also aren't used for anything yet
    ).freeze

    DEFAULT_CROSSPOST_OPTIONS = Platforms::DEFAULT_CROSSPOST_OPTIONS.merge(
      append_url: true,
      append_url_if_truncated: true,
      attach_link: false # not supported
    ).freeze

    IRRELEVANT_CONFIG_OPTIONS = [:append_url_label, :attach_link, :og_image].freeze
    EMBED_SUPPORTED = true

    def initialize
      @syndicates_mastodon_post = SyndicatesMastodonPost.new
    end

    def publish!(crosspost, crosspost_config, crosspost_content)
      @syndicates_mastodon_post.syndicate!(crosspost, crosspost_content.string)
    end

    def embed_html(crosspost)
      return nil unless crosspost.status == "published" && crosspost.url.present?

      # Mastodon embeds use an iframe
      <<~HTML
        <iframe src="#{crosspost.url}/embed" 
                class="mastodon-embed" 
                style="max-width: 100%; border: 0" 
                width="400" 
                allowfullscreen="allowfullscreen">
        </iframe>
        <script src="#{crosspost.account.credentials["base_url"]}/embed.js" async="async"></script>
      HTML
    end
  end
end
