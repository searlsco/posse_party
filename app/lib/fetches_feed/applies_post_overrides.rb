class FetchesFeed
  class AppliesPostOverrides
    def initialize
      @converts_html_to_plaintext = ConvertsHtmlToPlaintext.new
    end

    # Each Atom entry may contain a <posse:post> element, which can contain any of these attributes in a CDATA-escaped JSON string
    # These will override the corresponding elements in the Atom entry and any defaults set for the feed's posts
    def apply(post_attrs, syndication_config_string)
      syndication_config = RelaxedJson.parse(syndication_config_string)
      return post_attrs if syndication_config.blank?

      # Guard against junk data in the platform_overrides/media fields (the only that aren't one-level deep)
      syndication_config[:media] = [] unless syndication_config[:media].is_a?(Array)
      syndication_config[:platform_overrides] = {} unless syndication_config[:platform_overrides].is_a?(Hash)

      if syndication_config[:summary].present?
        syndication_config[:summary] = @converts_html_to_plaintext.convert(syndication_config[:summary])
      end
      if syndication_config[:content].present?
        syndication_config[:content] = @converts_html_to_plaintext.convert(syndication_config[:content])
      end

      post_attrs.merge(syndication_config.slice(
        # post-level overrides
        :id, # string, defaults to id tag content, then derived URL
        :published_at, # datetime, defaults to published tag content
        :updated_at, # datetime, defaults to updated tag content
        :url, # string, defaults to first link[rel=shorturl] URL, then first link[rel=alternate] URL, then first link URL in the Atom entry
        :alternate_url, # string, defaults to first rel=alternate URL in the Atom entry
        :related_url, # string, defaults to first rel=related URL in the Atom entry
        :short_url, # string, defaults to first rel=shorturl URL in the Atom entry
        :author_name, # string, defaults to author>name in the Atom entry
        :author_email, # string, defaults to author>email in the Atom entry
        :title, # string, defaults to text content of title in the Atom entry
        :subtitle, # string, defaults to text content of subtitle in the Atom entry
        :summary, # string, defaults to plaintext conversion of content of summary in the Atom entry
        :content, # string, defaults to plaintext conversion of content of content in the Atom entry
        # syndication configuration
        :syndicate, # true|false
        :format_string, # e.g. "{{title}} by {{author_name}}"
        :truncate, # true|false, will truncate the post to fit platform character limits
        :append_url, # true|false
        :append_url_if_truncated, # true|false, only applies if append_url is false and truncate is true
        :append_url_spacer, # string (e.g. " "), what to put between the content and the URL; for self-contained tweet-like posts, you may want a couple newlines
        :append_url_label, # string (e.g. "🔗"), when supported, will create a hyperlink to the appended source URL using this text instead of displaying the full URL
        :attach_link, # true|false, whether to attach an OpenGraph preview card to the post (supported by Bluesky and Threads)
        :og_image, # string, URL to an image to use as the website card image (supported by Bluesky)
        :og_title, # string, title to use on the website card (supported by Bluesky), defaults to title
        :og_description, # string, description to use on the website card (supported by Bluesky), defaults to summary
        # platform-specific configuration (nesting any of the above attributes underneath a known platform tag like "bsky")
        :platform_overrides, # hash of platform tag (e.g. "bsky") mapping to a hash of platform-specific overrides of the above attributes
        :media, # array of media objects [{"type": "image", "url": "https://example.com/image.jpg"}]
        :channel # either "feed" or "story" (the latter being for temporal story-type posts)
      ).transform_keys { |key|
        case key
        when :id
          :remote_id
        when :published_at
          :remote_published_at
        when :updated_at
          :remote_updated_at
        else
          key
        end
      })
    end
  end
end
