class PublishesCrosspost
  Result = Struct.new(:success?, :message, :error, :unretriable?, :needs_to_finish?, keyword_init: true)
  UnretriableError = Class.new(StandardError)
  RecoverableError = Class.new(StandardError)
  RecoverableLinkAttachmentError = Class.new(RecoverableError)
  # Raised by a platform that refuses one of the media items it was planned to attach (e.g. a video that's too large)
  class UnsupportedMediaError < StandardError
    def initialize(media, message)
      @media = media
      super(message)
    end

    attr_reader :media
  end

  OVERRIDABLE_FIELDS = {
    format_string: {type: :string},
    truncate: {type: :boolean},
    append_url: {type: :boolean},
    append_url_if_truncated: {type: :boolean},
    append_url_spacer: {type: :string},
    append_url_label: {type: :string},
    attach_link: {type: :boolean},
    og_image: {type: :string},
    media_fallback: {type: :enum, options: %w[link best_effort fail]}
  }.freeze

  def initialize
    @matches_platform_api = MatchesPlatformApi.new
    @tracks_crosspost_status = TracksCrosspostStatus.new
    @munges_config = MungesConfig.new
    @applies_media_plan = AppliesMediaPlan.new
    @rejects_media = RejectsMedia.new
    @composes_crosspost_content = ComposesCrosspostContent.new
    @recovers_from_invalid_link_attachment = RecoversFromInvalidLinkAttachment.new
  end

  def publish(crosspost_id)
    crosspost = Crosspost.includes(:account, :post).find(crosspost_id)
    return Result.new(success?: true, message: "Not the WIP crosspost for the account") unless crosspost.wip?
    crosspost.update!(last_attempted_at: Now.time, attempts: crosspost.attempts + 1)
    @tracks_crosspost_status.track(crosspost) do
      api = @matches_platform_api.match(crosspost.account)
      crosspost_config = @munges_config.munge(crosspost, api.default_crosspost_options)
      if crosspost_config.syndicate && api.supports_channel?(crosspost_config.channel)
        syndicate(crosspost, api, crosspost_config, rejected_urls: crosspost.metadata.fetch("rejected_media_urls", []))
      else
        crosspost.update!(status: "skipped")
        Result.new(success?: true, message: "Crosspost was not configured to be syndicated for channel #{crosspost_config.channel}")
      end
    end
  end

  private

  def syndicate(crosspost, api, crosspost_config, rejected_urls: [])
    @applies_media_plan.apply(crosspost_config, api, crosspost.account, rejected_urls:)
    crosspost_content = @composes_crosspost_content.compose(crosspost_config, api.post_constraints)
    api.publish!(crosspost, crosspost_config, crosspost_content)
  rescue RecoverableLinkAttachmentError
    # Recompose content with the link appended instead of attached
    @recovers_from_invalid_link_attachment.recover(crosspost, crosspost_config, api, failing_content: crosspost_content)
  rescue UnsupportedMediaError => e
    # Plan again from scratch, treating the refused item like any other media the platform can't attach
    syndicate(crosspost, api, @munges_config.munge(crosspost, api.default_crosspost_options), rejected_urls: @rejects_media.reject(crosspost, e.media))
  end
end
