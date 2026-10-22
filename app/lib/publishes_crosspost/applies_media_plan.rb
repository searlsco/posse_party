class PublishesCrosspost
  class AppliesMediaPlan
    def initialize
      @applies_format_string = AppliesFormatString.new
    end

    # Narrows crosspost_config.media to what the platform can attach, as media_fallback directs:
    # - "link" (default): attach nothing unless everything fits
    # - "best_effort": attach whatever fits
    # - "fail": refuse to publish unless everything fits
    # Whenever media is left behind or displaces the website card, the post still links back to the source.
    # Platforms without media constraints get no media here (Instagram and YouTube read the post's media themselves).
    def apply(crosspost_config, api, account, rejected_urls: [])
      media = Array(crosspost_config.media).map { |item| to_crosspost_media(item) }
      return crosspost_config.tap { |config| config.media = [] } if media.empty? || (media_constraints = api.media_constraints(account)).nil?

      attachable = attachable_subset(media.reject { |item| rejected_urls.include?(item.url) }, media_constraints)
      planned = if attachable.size == media.size
        attachable
      else
        case crosspost_config.media_fallback
        when "best_effort" then attachable
        when "fail" then raise UnretriableError, "Can only attach #{attachable.size} of this post's #{media.size} media items, and media_fallback is \"fail\""
        else []
        end
      end

      crosspost_config.media = planned
      if planned.any? && crosspost_config.attach_link
        crosspost_config.attach_link = false
        ensure_link!(crosspost_config)
      elsif planned.size < media.size && !crosspost_config.attach_link
        ensure_link!(crosspost_config)
      end
      crosspost_config
    end

    private

    def to_crosspost_media(item)
      CrosspostMedia.new(**item.to_h.symbolize_keys.slice(*CrosspostMedia.members))
    end

    def attachable_subset(media, media_constraints)
      kind = media.find { |item| item.image? || item.video? }&.type
      media
        .select { |item| (item.image? || item.video?) && item.url.present? }
        .select { |item| media_constraints.mixable || item.type == kind }
        .each_with_object([]) { |item, kept| kept << item if fits?(kept + [item], media_constraints) }
    end

    def fits?(media, media_constraints)
      [
        [media.count(&:image?), media_constraints.max_images],
        [media.count(&:video?), media_constraints.max_videos],
        [media.size, media_constraints.max_items]
      ].all? { |count, max| max.nil? || count <= max }
    end

    def ensure_link!(crosspost_config)
      return if crosspost_config.url.blank? || @applies_format_string.apply(crosspost_config).include?(crosspost_config.url)

      crosspost_config.append_url = true
    end
  end
end
