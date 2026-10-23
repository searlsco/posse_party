class Platforms::Mastodon
  class FetchesInstanceLimits
    Limits = Struct.new(:max_media_attachments, :image_size_limit, :video_size_limit, :supported_mime_types, keyword_init: true)

    # Mastodon's own defaults, for servers (older ones, or other software speaking its API) that don't say
    # https://github.com/mastodon/mastodon/blob/main/app/models/media_attachment.rb
    DEFAULTS = {
      max_media_attachments: 4,
      image_size_limit: 16.megabytes,
      video_size_limit: 99.megabytes,
      supported_mime_types: %w[image/jpeg image/png image/gif image/webp video/mp4 video/webm video/quicktime]
    }.freeze

    # https://docs.joinmastodon.org/methods/instance/#v2
    def fetch(base_url)
      Limits.new(**Rails.cache.fetch("mastodon_instance_limits/#{base_url}", expires_in: 1.day) {
        DEFAULTS.merge(advertised_limits(base_url).compact)
      })
    end

    private

    def advertised_limits(base_url)
      response = HTTParty.get("#{base_url}/api/v2/instance")
      configuration = (response.parsed_response["configuration"] if response.success? && response.parsed_response.is_a?(Hash)) || {}
      {
        max_media_attachments: configuration.dig("statuses", "max_media_attachments"),
        image_size_limit: configuration.dig("media_attachments", "image_size_limit"),
        video_size_limit: configuration.dig("media_attachments", "video_size_limit"),
        supported_mime_types: configuration.dig("media_attachments", "supported_mime_types")
      }
    end
  end
end
