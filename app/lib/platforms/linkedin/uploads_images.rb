class Platforms::Linkedin
  # https://learn.microsoft.com/en-us/linkedin/marketing/community-management/shares/images-api
  class UploadsImages
    MAX_IMAGE_BYTES = 8.megabytes

    def initialize
      @initiates_image_upload = InitiatesImageUpload.new
      @downloads_media = DownloadsMedia.new
      @prepares_image_upload = PreparesImageUpload.new
    end

    # Returns the post content for one image, or a multi-image post for several
    def upload(media, access_token:, person_urn:)
      images = media.map { |item| {id: upload_image(item, access_token:, person_urn:), altText: item.alt}.compact }
      (images.size == 1) ? {media: images.first} : {multiImage: {images:}}
    end

    private

    def upload_image(item, access_token:, person_urn:)
      download = @downloads_media.download(item)
      image = @prepares_image_upload.prepare(item, download.bytes, download.content_type, max_bytes: MAX_IMAGE_BYTES, accepted_types: %w[image/jpeg image/png image/gif])
      upload = @initiates_image_upload.initiate(access_token:, person_urn:)
      raise "Failed to initiate LinkedIn image upload for #{item.url}. #{upload.message}" unless upload.success?

      response = HTTParty.put(upload.upload_url, body: image.bytes, headers: {"Authorization" => "Bearer #{access_token}", "Content-Type" => image.content_type})
      raise "Failed to upload #{item.url} to LinkedIn (HTTP #{response.code}). Response: #{response.body}" unless response.success?

      upload.image_urn
    end
  end
end
