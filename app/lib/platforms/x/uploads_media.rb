class Platforms::X
  # https://docs.x.com/x-api/media/quickstart/media-upload-chunked
  class UploadsMedia
    MAX_IMAGE_BYTES = 5.megabytes
    MAX_VIDEO_BYTES = 512.megabytes

    def initialize
      @downloads_media = DownloadsMedia.new
      @prepares_image_upload = PreparesImageUpload.new
    end

    # Returns the media ID to attach to a post
    def upload(item, client)
      media_id = item.video? ? upload_video(item, client) : upload_image(item, client)
      if item.alt.present?
        client.post("media/metadata", {id: media_id, metadata: {alt_text: {text: item.alt.truncate(1000)}}}.to_json)
      end
      media_id
    end

    private

    def upload_image(item, client)
      download = @downloads_media.download(item)
      image = @prepares_image_upload.prepare(item, download.bytes, download.content_type, max_bytes: MAX_IMAGE_BYTES, accepted_types: %w[image/jpeg image/png image/webp image/gif])
      X::MediaUploader.upload_binary(client:, content: image.bytes, media_category: "tweet_image").fetch("id")
    end

    def upload_video(item, client)
      download = @downloads_media.download(item, max_bytes: MAX_VIDEO_BYTES)
      media = X::MediaUploader.chunked_upload(client:, file_path: download.file.path, media_category: "tweet_video", media_type: "video/mp4", chunk_size_mb: 4)
      if X::MediaUploader.await_processing(client:, media:)&.dig("processing_info", "state") == "failed"
        raise PublishesCrosspost::UnsupportedMediaError.new(item, "X failed to process video #{item.url}")
      end

      media.fetch("id")
    end
  end
end
