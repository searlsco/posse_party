require "digest"

class Platforms::Mastodon
  class UploadsMedia
    def initialize
      @fetches_instance_limits = FetchesInstanceLimits.new
      @downloads_media = DownloadsMedia.new
      @prepares_image_upload = PreparesImageUpload.new
    end

    # Returns the media attachment's ID. Videos (and sometimes images) are still processing when this returns
    # https://docs.joinmastodon.org/methods/media/#v2
    def upload(item, base_url:, access_token:)
      limits = @fetches_instance_limits.fetch(base_url)
      bytes, content_type = file_for(item, limits)
      boundary = "PosseParty#{Digest::SHA256.hexdigest(bytes)[0, 32]}"
      response = HTTParty.post(
        "#{base_url}/api/v2/media",
        headers: {"Authorization" => "Bearer #{access_token}", "Content-Type" => "multipart/form-data; boundary=#{boundary}"},
        body: multipart_body(boundary, bytes:, content_type:, description: item.alt)
      )
      if [413, 415, 422].include?(response.code)
        raise PublishesCrosspost::UnsupportedMediaError.new(item, "Mastodon refused #{item.url}: #{response.body}")
      elsif response.code == 403
        # Usually an access token created before media was supported, without the write:media scope. Retrying won't help
        raise PublishesCrosspost::UnretriableError, "Mastodon wouldn't let this account upload #{item.url} (HTTP 403). Make sure the access token has the write:media scope (see docs/account_setup/mastodon.md). Response: #{response.body}"
      elsif !response.success? || response["id"].blank?
        raise "Failed to upload #{item.url} to Mastodon (HTTP #{response.code}). Response: #{response.body}"
      end

      response["id"]
    end

    private

    def file_for(item, limits)
      download = @downloads_media.download(item, max_bytes: item.video? ? limits.video_size_limit : DownloadsMedia::MAX_IMAGE_BYTES)
      if item.video?
        [download.bytes, download.content_type]
      else
        image = @prepares_image_upload.prepare(item, download.bytes, download.content_type, max_bytes: limits.image_size_limit, accepted_types: limits.supported_mime_types)
        [image.bytes, image.content_type]
      end
    ensure
      download&.file&.close!
    end

    # Built by hand (rather than by HTTParty) so the boundary is stable for the same media
    def multipart_body(boundary, bytes:, content_type:, description:)
      [
        "--#{boundary}\r\n",
        "Content-Disposition: form-data; name=\"file\"; filename=\"media.#{Marcel::Magic.new(content_type).extensions.first}\"\r\n",
        "Content-Type: #{content_type}\r\n\r\n",
        bytes.b,
        "\r\n",
        ("--#{boundary}\r\nContent-Disposition: form-data; name=\"description\"\r\n\r\n#{description}\r\n" if description.present?),
        "--#{boundary}--\r\n"
      ].compact.map(&:b).join
    end
  end
end
