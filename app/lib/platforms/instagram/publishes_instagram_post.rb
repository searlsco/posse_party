class Platforms::Instagram
  class PublishesInstagramPost
    # These can work themselves out through more polling more often than not
    # https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/error-codes
    TEMPORAL_ERROR_SUBCODES = [
      "2207008", # container_id doesn't exist yet, wait for it to
      "2207027" # Media not ready (usually downloading or processing)
    ].freeze

    # No point in retrying from the beginning. Give up.
    # https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/error-codes
    UNRETRIABLE_ERROR_SUBCODES = [
      "2207057", # invalid thumbnail offset
      "2207051", # flagged as spam -- repeatedly retrying could catch a ban
      "2207023", # unknown media type
      "2207028", # invalid carousel (gotta be 2 to 10)
      "2207035", # invalid use of a product tag on a video
      "2207036", # invalid product tags
      "2207040", # too many tags
      "2207026", # Unsupported format
      "2207004", # image too large
      "2207005", # invalid image format
      "2207009", # invalid aspect ratio
      "2207010" # caption too long
    ].freeze

    def initialize
      @api = SyndicationApi.new
      @builds_instagram_config = BuildsInstagramConfig.new
      @translates_instagram_post = TranslatesInstagramPost.new
      @builds_friendly_error_message = BuildsFriendlyErrorMessage.new
    end

    def publish(crosspost:, mode:, crosspost_config: nil, crosspost_content: nil)
      raise ArgumentError, "Unknown mode: #{mode.inspect}" unless [:syndicate, :finish].include?(mode)
      return build_result(:failure, :config_missing) if (config = @builds_instagram_config.build(crosspost.account)).blank?
      return build_result(:success, :unnecessary) if crosspost.status != "wip" || crosspost.remote_id.present?
      return build_result(:failure, :missing_container) if mode == :finish && crosspost.metadata["post"].blank?

      instagram_post, channel = prepare_instagram_post(crosspost:, mode:, crosspost_config:, crosspost_content:)
      if instagram_post.medias.size == 1
        publish_single_media(crosspost, config, channel:, instagram_post:)
      else
        publish_carousel(crosspost, config, channel:, instagram_post:)
      end
    rescue Platforms::Instagram::ApiError => error
      handle_api_error(error:, mode:, crosspost:, config:, instagram_post:)
    rescue Platforms::Instagram::ProcessingError => error
      handle_processing_error(error:, mode:, crosspost:, config:, instagram_post:)
    rescue => error
      PublishesCrosspost::Result.new(success?: false, message: "Failed to #{mode} to Instagram: #{error.message}", error:)
    end

    private

    def prepare_instagram_post(crosspost:, mode:, crosspost_config:, crosspost_content:)
      case mode
      when :syndicate
        crosspost.update!(content: crosspost_content.string)
        channel = crosspost_config.channel
        instagram_post = @translates_instagram_post.from_crosspost(crosspost, channel:)
      when :finish
        instagram_post = @translates_instagram_post.from_json(crosspost.metadata["post"])
        channel = channel_for(instagram_post)
      end

      [instagram_post, channel]
    end

    def publish_single_media(crosspost, config, channel:, instagram_post:)
      media = instagram_post.medias.first

      if media.container_id.nil?
        media.container_id = @api.create_single_media_container(instagram_post, config, channel:)
        persist_instagram_metadata!(crosspost, {"post" => instagram_post.to_json})
      end

      publish_or_queue(crosspost:, config:, channel:,
        container_id: media.container_id,
        ready_to_publish: all_medias_uploaded_bang?(crosspost, config, instagram_post))
    end

    def publish_carousel(crosspost, config, channel:, instagram_post:)
      instagram_post.medias.select { |m| m.container_id.blank? }.each do |media|
        media.container_id = @api.create_carousel_media_container(media, config)
        persist_instagram_metadata!(crosspost, {"post" => instagram_post.to_json})
      end

      medias_uploaded = all_medias_uploaded_bang?(crosspost, config, instagram_post)

      if medias_uploaded && (carousel_container_id = crosspost.metadata["carousel_container_id"]).nil?
        child_ids = instagram_post.medias.map(&:container_id)
        carousel_container_id = @api.create_carousel_container(instagram_post, child_ids, config)
        persist_instagram_metadata!(crosspost, {"carousel_container_id" => carousel_container_id})
      end

      publish_or_queue(crosspost:, config:, channel:,
        container_id: carousel_container_id,
        ready_to_publish: medias_uploaded)
    end

    def need_to_finish_publishing_later
      PublishesCrosspost::Result.new(
        success?: true,
        needs_to_finish?: true,
        message: "Instagram post queued for publishing (waiting for upload completion)"
      )
    end

    def publish_or_queue(crosspost:, config:, channel:, container_id:, ready_to_publish:)
      if ready_to_publish
        @api.publish(crosspost, container_id, config, channel:)
      else
        need_to_finish_publishing_later
      end
    end

    def all_medias_uploaded_bang?(crosspost, config, instagram_post)
      return true if crosspost.metadata["medias_uploaded"]

      instagram_post.medias.all? { |media|
        !media.video? || @api.upload_finished?(media.container_id, config)
      }.tap do |medias_uploaded|
        persist_instagram_metadata!(crosspost, {"medias_uploaded" => medias_uploaded})
      end
    end

    def persist_instagram_metadata!(crosspost, attributes)
      crosspost.update!(metadata: crosspost.metadata.merge(attributes.compact))
    end

    def channel_for(instagram_post)
      (instagram_post.media_type == "STORIES") ? "story" : "feed"
    end

    def build_result(status, message_key)
      message = case message_key
      when :unnecessary then "Asked to publish Instagram post, but it wasn't necessary"
      when :missing_container then "Asked to finish uploading Instagram post, but no container was provided"
      when :config_missing then "Can't publish to Instagram because credentials weren't configured"
      end

      PublishesCrosspost::Result.new(
        success?: status == :success,
        message:
      )
    end

    def handle_api_error(error:, mode:, crosspost:, config: nil, instagram_post: nil)
      if worth_waiting_for?(error)
        need_to_finish_publishing_later
      else
        report_instagram_failure(error, mode, crosspost, instagram_post)
      end
    end

    def handle_processing_error(error:, mode:, crosspost:, config: nil, instagram_post: nil)
      if worth_waiting_for?(error)
        need_to_finish_publishing_later
      elsif config.present? && (container_id = extract_container_id(error, crosspost, instagram_post))
        channel = instagram_post ? channel_for(instagram_post) : "feed"
        at_least_try_to_publish_a_thing_if_it_fails_during_processing_wcgw(
          mode, crosspost, config, instagram_post, container_id, channel
        )
      else
        report_instagram_failure(error, mode, crosspost, instagram_post)
      end
    end

    def report_instagram_failure(error, mode, crosspost, instagram_post)
      PublishesCrosspost::Result.new(
        success?: false,
        message: @builds_friendly_error_message.build(
          error,
          media_type: instagram_post&.media_type,
          action_description: "#{(mode == :syndicate) ? "publishing" : "finishing publication of"} crosspost [#{crosspost.id}]"
        ),
        error:,
        unretriable?: unretriable?(error)
      )
    end

    def extract_container_id(error, crosspost, instagram_post)
      error.container_id ||
        instagram_post&.medias&.first&.container_id ||
        crosspost.metadata["carousel_container_id"]
    end

    def at_least_try_to_publish_a_thing_if_it_fails_during_processing_wcgw(mode, crosspost, config, instagram_post, container_id, channel)
      @api.publish(crosspost, container_id, config, channel:)
    rescue Platforms::Instagram::ApiError => error
      message = @builds_friendly_error_message.build(
        error,
        media_type: instagram_post.media_type,
        action_description: "#{(mode == :syndicate) ? "publishing" : "finishing publication of"} crosspost [#{crosspost.id}]"
      )
      PublishesCrosspost::Result.new(
        success?: false,
        message:,
        error: error,
        unretriable?: unretriable?(error)
      )
    end

    def worth_waiting_for?(error)
      TEMPORAL_ERROR_SUBCODES.include?(error.subcode)
    end

    def unretriable?(error)
      UNRETRIABLE_ERROR_SUBCODES.include?(error.subcode)
    end
  end
end
