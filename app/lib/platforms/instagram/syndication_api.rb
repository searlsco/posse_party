class Platforms::Instagram
  class SyndicationApi
    def initialize
      @calls_instagram_api = CallsInstagramApi.new
    end

    def publish(crosspost, container_id, config, channel: "feed")
      if crosspost.remote_id.blank? && crosspost.url.blank?
        media_id = publish_container(container_id, config)
        finalize(crosspost, media_id, config, channel: channel)
      else
        PublishesCrosspost::Result.new(
          success?: true,
          message: "Instagram post already published"
        )
      end
    end

    def create_single_media_container(instagram_post, config, channel:)
      media = instagram_post.medias.first
      query = {access_token: config.access_token}
      # Stories omit captions entirely
      query[:caption] = instagram_post.caption unless channel == "story"

      if channel == "story"
        query[:media_type] = "STORIES"
        if media.video?
          query[:video_url] = media.url
        else
          query[:image_url] = media.url
        end
      elsif media.video?
        # v24.0 deprecates VIDEO; use REELS for single-video posts
        query[:media_type] = "REELS"
        query[:video_url] = media.url
      else
        query[:image_url] = media.url
      end

      api_call!(method: :post, path: "#{config.user_id}/media", query:).id
    end

    def create_carousel_media_container(media, config)
      api_call!(method: :post, path: "#{config.user_id}/media", query: {
        access_token: config.access_token,
        is_carousel_item: true,
        media_type: media.media_type,
        image_url: (media.url unless media.video?),
        video_url: (media.url if media.video?)
      }.compact).id
    end

    def create_carousel_container(instagram_post, media_containers, config)
      api_call!(
        method: :post,
        path: "#{config.user_id}/media",
        query: {
          access_token: config.access_token,
          media_type: "CAROUSEL",
          caption: instagram_post.caption,
          children: media_containers.join(",")
        }
      ).id
    end

    # Public: One-shot diagnostic attempt to publish a container.
    # See method body for return contract.
    def try_publish_for_diagnostics(container_id, config)
      media_id = publish_container(container_id, config)
      {published: true, media_id: media_id}
    rescue Platforms::Instagram::ApiError => e
      e
    rescue
      # In tests without a cassette (or other unexpected errors), silently
      # fall back to prior behavior by returning nil.
      nil
    end

    def upload_finished?(container_id, config)
      res = api_call!(
        method: :get,
        path: container_id.to_s,
        query: {access_token: config.access_token, fields: "status_code,status"}
      )
      status = res.data[:status_code]
      case status
      when "FINISHED" then true
      when "IN_PROGRESS" then false
      else
        raise Platforms::Instagram::ProcessingError.new(
          container_id: container_id,
          code: status,
          subcode: res.data[:status],
          raw: res.data
        )
      end
    end

    private

    def get_media_permalink(media_id, config)
      api_call!(
        method: :get,
        path: media_id.to_s,
        query: {access_token: config.access_token, fields: "permalink"}
      ).data[:permalink]
    end

    # Finalize a successful publish given a media_id
    def finalize(crosspost, media_id, config, channel: "feed")
      crosspost.update!(
        status: "published",
        remote_id: media_id,
        url: (get_media_permalink(media_id, config) unless channel == "story"),
        published_at: Now.time
      )

      PublishesCrosspost::Result.new(
        success?: true,
        message: "Successfully published to Instagram"
      )
    end

    def publish_container(container_id, config)
      api_call!(
        method: :post,
        path: "#{config.user_id}/media_publish",
        query: {access_token: config.access_token, creation_id: container_id}
      ).id
    end

    def api_call!(method:, path:, query: {})
      res = @calls_instagram_api.call(method: method, path: path, query: query)
      if res.success?
        res
      else
        raise Platforms::Instagram::ApiError.new(
          message: res.message,
          code: res.error_code,
          subcode: res.error_subcode,
          type: res.error_type,
          fbtrace_id: res.fbtrace_id,
          request: {method: method, path: path, query: query},
          raw: res.data
        )
      end
    end
  end
end
