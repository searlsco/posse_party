class PublishesCrosspost
  Result = Struct.new(:success?, :message, :error, :unretriable?, :needs_to_finish?, keyword_init: true)
  UnretriableError = Class.new(StandardError)
  RecoverableError = Class.new(StandardError)
  RecoverableLinkAttachmentError = Class.new(RecoverableError)

  def initialize
    @matches_platform_api = MatchesPlatformApi.new
    @tracks_crosspost_status = TracksCrosspostStatus.new
    @munges_config = MungesConfig.new
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
        crosspost_content = @composes_crosspost_content.compose(crosspost_config, api.post_constraints)
        begin
          api.publish!(crosspost, crosspost_config, crosspost_content)
        rescue RecoverableLinkAttachmentError
          # Recompose content with the link appended instead of attached
          @recovers_from_invalid_link_attachment.recover(crosspost, crosspost_config, api, failing_content: crosspost_content)
        end
      else
        crosspost.update!(status: "skipped")
        Result.new(success?: true, message: "Crosspost was not configured to be syndicated for channel #{crosspost_config.channel}")
      end
    end
  end

  OVERRIDABLE_FIELDS = {
    format_string: {type: :string},
    truncate: {type: :boolean},
    append_url: {type: :boolean},
    append_url_if_truncated: {type: :boolean},
    append_url_spacer: {type: :string},
    append_url_label: {type: :string},
    attach_link: {type: :boolean},
    og_image: {type: :string}
  }.freeze
end
