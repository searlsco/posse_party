module Platforms
  class Facebook < Base
    TAG = "facebook"
    LABEL = "Facebook"
    API_BASE_URL = "https://graph.facebook.com/v23.0/"

    REQUIRED_CREDENTIALS = %w[page_id page_access_token].freeze

    POST_CONSTRAINTS = Constants::DEFAULT_POST_CONSTRAINTS.merge(
      character_limit: 63206  # Facebook posts can be quite long
    ).freeze

    DEFAULT_CROSSPOST_OPTIONS = Platforms::DEFAULT_CROSSPOST_OPTIONS.merge(
      attach_link: true
    ).freeze

    IRRELEVANT_CONFIG_OPTIONS = [:append_url_label, :og_image].freeze
    EMBED_SUPPORTED = true

    def initialize
      @syndicates_facebook_post = SyndicatesFacebookPost.new
    end

    def publish!(crosspost, crosspost_config, crosspost_content)
      @syndicates_facebook_post.syndicate!(crosspost, crosspost_config, crosspost_content.string)
    end

    def embed_html(crosspost)
      return nil unless crosspost.status == "published" && crosspost.url.present?

      # Facebook embeds use an iframe approach
      <<~HTML
        <iframe src="https://www.facebook.com/plugins/post.php?href=#{CGI.escape(crosspost.url)}&show_text=true&width=500" 
                width="500" 
                height="600" 
                style="border:none;overflow:hidden" 
                scrolling="no" 
                frameborder="0" 
                allowfullscreen="true" 
                allow="autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share">
        </iframe>
      HTML
    end
  end
end
