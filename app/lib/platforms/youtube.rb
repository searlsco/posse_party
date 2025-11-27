module Platforms
  class Youtube < Base
    TAG = "youtube"
    LABEL = "YouTube"

    REQUIRED_CREDENTIALS = %w[client_id client_secret access_token refresh_token].freeze

    POST_CONSTRAINTS = Constants::DEFAULT_POST_CONSTRAINTS.merge(
      character_limit: 100  # YouTube title limit
    ).freeze

    DEFAULT_CROSSPOST_OPTIONS = Platforms::DEFAULT_CROSSPOST_OPTIONS.merge(
      append_url_spacer: "\n\n"
    ).freeze

    RENEWABLE = true
    RENEWAL_URL_SUPPORTED = true
    IRRELEVANT_CONFIG_OPTIONS = [:append_url_label, :attach_link, :og_image].freeze
    EMBED_SUPPORTED = true

    def initialize
      @syndicates_youtube_post = SyndicatesYoutubePost.new
      @potentially_tells_user_to_renew_youtube_access_token = PotentiallyTellsUserToRenewYoutubeAccessToken.new
    end

    def publish!(crosspost, crosspost_config, crosspost_content)
      if crosspost.post.media.size == 1 && crosspost.post.media.first["type"] == "video"
        @syndicates_youtube_post.syndicate!(crosspost, crosspost_config, crosspost_content.string)
      else
        crosspost.update!(status: "skipped")
        PublishesCrosspost::Result.new(
          success?: true,
          message: "Skipped: YouTube posts require exactly one video"
        )
      end
    end

    def renew!(account)
      @potentially_tells_user_to_renew_youtube_access_token.potentially_tell(account)
    end

    def renewal_url(account, state)
      oauth_params = {
        response_type: "code",
        client_id: account.credentials["client_id"],
        redirect_uri: Rails.application.routes.url_helpers.credential_renewals_youtube_url,
        scope: "https://www.googleapis.com/auth/youtube.upload",
        access_type: "offline",
        prompt: "consent",
        state: state
      }

      "https://accounts.google.com/o/oauth2/auth?#{oauth_params.to_query}"
    end

    def embed_html(crosspost)
      return nil unless crosspost.published?
      return nil if crosspost.remote_id.blank?

      video_id = extract_video_id(crosspost.remote_id)
      return nil unless video_id

      %(<iframe width="560" height="315" src="https://www.youtube.com/embed/#{video_id}" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>)
    end

    private

    def extract_video_id(remote_id)
      # YouTube video IDs are typically stored as the video ID itself
      # or as part of a URL like https://youtube.com/watch?v=VIDEO_ID
      return remote_id if remote_id.match?(/^[a-zA-Z0-9_-]{11}$/)

      # Try to extract from URL
      if (match = remote_id.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/))
        match[1]
      end
    end
  end
end
