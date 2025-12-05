module Platforms
  class X < Base
    TAG = "x"
    LABEL = "X (Twitter)"

    REQUIRED_CREDENTIALS = %w[api_key access_token api_key_secret access_token_secret].freeze

    POST_CONSTRAINTS = Constants::DEFAULT_POST_CONSTRAINTS.merge(
      character_limit: 280,
      counter: TwitterText::Counter.new,
      hashtag_pattern: TwitterText::HASHTAG_PATTERN,
      url_pattern: TwitterText::URL_PATTERN
    ).freeze

    DEFAULT_CROSSPOST_OPTIONS = Platforms::DEFAULT_CROSSPOST_OPTIONS.merge(
      append_url: true,
      append_url_if_truncated: true,
      attach_link: false # not supported
    ).freeze

    IRRELEVANT_CONFIG_OPTIONS = [:append_url_label, :attach_link, :og_image].freeze
    EMBED_SUPPORTED = true

    def initialize
      @syndicates_x_post = SyndicatesXPost.new
    end

    def setup_docs_available?
      true
    end

    def publish!(crosspost, crosspost_config, crosspost_content)
      @syndicates_x_post.syndicate!(crosspost, crosspost_content.string)
    end

    def embed_html(crosspost)
      return nil unless crosspost.status == "published" && crosspost.url.present?

      <<~HTML
        <blockquote class="twitter-tweet">
          <a href="#{crosspost.url}"></a>
        </blockquote>
        <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
      HTML
    end
  end
end
