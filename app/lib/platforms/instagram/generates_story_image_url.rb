require "digest"

class Platforms::Instagram
  class GeneratesStoryImageUrl
    def initialize
      @letterboxes_image_with_vips = LetterboxesImageWithVips.new
    end

    def generate(crosspost, source_url)
      Rails.application.routes.url_helpers.instagram_story_image_url(
        key: TemporaryAsset.find_or_initialize_by(crosspost: crosspost).tap { |temporary_asset|
          temporary_asset.update!(
            key: temporary_asset.key.presence || story_image_key(crosspost, source_url),
            bytes: temporary_asset.bytes.presence || story_image_bytes(source_url),
            content_type: temporary_asset.content_type.presence || "image/jpeg"
          )
        }.key
      )
    end

    private

    def story_image_bytes(source_url)
      @letterboxes_image_with_vips.letterbox(HTTParty.get(source_url, follow_redirects: true, format: :plain).body)
    end

    def story_image_key(crosspost, source_url)
      Digest::SHA256.hexdigest([crosspost.post.remote_id, crosspost.account.credentials.fetch("user_id"), source_url].join("|"))
    end
  end
end
