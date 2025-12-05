module Platforms
  class Bsky < Base
    TAG = "bsky"
    LABEL = "Bluesky"

    REQUIRED_CREDENTIALS = %w[email password].freeze
    CREDENTIAL_LABELS = {
      "password" => "App Password"
    }.freeze

    POST_CONSTRAINTS = Constants::DEFAULT_POST_CONSTRAINTS.merge(
      character_limit: 300,
      counter: ->(content) {
        # Bsky counts grapheme clusters with no special rules for handles or URLs
        content.grapheme_clusters.count
      }
    ).freeze

    DEFAULT_CROSSPOST_OPTIONS = Platforms::DEFAULT_CROSSPOST_OPTIONS.merge(
      url_transformer: AbbreviatesUrl.new,
      truncation_marker: "...",
      append_url_label_supported: true,
      append_url_label: "🔗",
      attach_link: true
    ).freeze

    EMBED_SUPPORTED = true

    def initialize
      @assembles_rich_text_facets = AssemblesRichTextFacets.new
      @syndicates_bsky_post = SyndicatesBskyPost.new
    end

    def publish!(crosspost, crosspost_config, crosspost_content)
      rich_text_facets = @assembles_rich_text_facets.assemble(crosspost_content.string, crosspost_content.pattern_ranges)
      @syndicates_bsky_post.syndicate!(crosspost, crosspost_config, crosspost_content.string, rich_text_facets)
    end

    def embed_html(crosspost)
      return nil unless crosspost.status == "published" && crosspost.url.present?

      # Use Bluesky's oEmbed API to get the proper embed code
      oembed_url = "https://embed.bsky.app/oembed?url=#{CGI.escape(crosspost.url)}"
      begin
        response = HTTParty.get(oembed_url)
        if response.success? && response.parsed_response["html"]
          response.parsed_response["html"]
        else
          # Fallback to manual blockquote if oEmbed fails
          <<~HTML
            <blockquote>
              <p>Loading Bluesky post...</p>
              <a href="#{crosspost.url}">View on Bluesky</a>
            </blockquote>
            <script async src="https://embed.bsky.app/static/embed.js" charset="utf-8"></script>
          HTML
        end
      rescue => e
        Rails.logger.error "Failed to fetch Bluesky oEmbed: #{e.message}"
        # Fallback to simple link
        %(<p><a href="#{crosspost.url}" target="_blank" rel="noopener">View on Bluesky</a></p>)
      end
    end
  end
end
