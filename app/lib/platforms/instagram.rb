module Platforms
  class Instagram < Base
    TAG = "instagram"
    LABEL = "Instagram"

    API_BASE_URL = "https://graph.instagram.com/v24.0/"

    REQUIRED_CREDENTIALS = %w[app_id app_secret user_id access_token].freeze

    POST_CONSTRAINTS = Constants::DEFAULT_POST_CONSTRAINTS.merge(
      character_limit: 2000
    ).freeze

    DEFAULT_CROSSPOST_OPTIONS = Platforms::DEFAULT_CROSSPOST_OPTIONS.merge(
      format_string: "{{content}}",
      append_url: true,
      append_url_if_truncated: true,
      append_url_spacer: "\n\nSee the full post at:\n"
    ).freeze

    RENEWABLE = true
    IRRELEVANT_CONFIG_OPTIONS = [:append_url_label, :attach_link, :og_image].freeze
    EMBED_SUPPORTED = true
    SUPPORTED_CHANNELS = %w[feed story].freeze

    def initialize
      @publishes_instagram_post = PublishesInstagramPost.new
      @renews_instagram_access_token = RenewsInstagramAccessToken.new
    end

    def publish!(crosspost, crosspost_config, crosspost_content)
      if crosspost.post.media.present?
        @publishes_instagram_post.publish(
          crosspost: crosspost,
          mode: :syndicate,
          crosspost_config: crosspost_config,
          crosspost_content: crosspost_content
        )
      else
        crosspost.update!(status: "skipped")
        PublishesCrosspost::Result.new(
          success?: true,
          message: "Skipped: Instagram posts require media"
        )
      end
    end

    def finishable?
      true
    end

    def finish!(crosspost)
      @publishes_instagram_post.publish(crosspost: crosspost, mode: :finish)
    end

    def renew!(account)
      @renews_instagram_access_token.renew!(account)
    end

    def embed_html(crosspost)
      return nil unless crosspost.status == "published" && crosspost.url.present?

      <<~HTML
        <blockquote class="instagram-media" data-instgrm-version="14" style="width:100%;">
          <a href="#{crosspost.url}"></a>
        </blockquote>
        <script async src="//www.instagram.com/embed.js"></script>
      HTML
    end
  end
end
