class Platforms::Bsky
  class UploadsImages
    MAX_IMAGE_BYTES = 2_000_000

    def initialize
      @downloads_media = DownloadsMedia.new
      @prepares_image_upload = PreparesImageUpload.new
    end

    def upload(media, session)
      {
        "$type" => "app.bsky.embed.images",
        "images" => media.map { |item| upload_image(item, session) }
      }
    end

    private

    def upload_image(item, session)
      download = @downloads_media.download(item)
      image = @prepares_image_upload.prepare(item, download.bytes, download.content_type, max_bytes: MAX_IMAGE_BYTES, accepted_types: %w[image/jpeg image/png image/webp])
      response = HTTParty.post(
        "#{session.pds}/xrpc/com.atproto.repo.uploadBlob",
        body: image.bytes,
        headers: {"Authorization" => "Bearer #{session.access_token}", "Content-Type" => image.content_type}
      )
      if [413, 415, 422].include?(response.code) || (response.code == 400 && response.parsed_response.is_a?(Hash) && %w[BlobTooLarge InvalidMimeType].include?(response["error"]))
        raise PublishesCrosspost::UnsupportedMediaError.new(item, "Bsky refused #{item.url}: #{response.body}")
      end
      raise "Failed to upload #{item.url} to Bsky. Response: #{response.body}" unless response.success?

      {
        "alt" => item.alt.to_s,
        "image" => response["blob"],
        "aspectRatio" => {"width" => image.width, "height" => image.height}
      }
    ensure
      download&.file&.close!
    end
  end
end
