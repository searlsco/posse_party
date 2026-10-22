class Platforms::Linkedin
  # https://learn.microsoft.com/en-us/linkedin/marketing/community-management/shares/videos-api
  class UploadsVideo
    MAX_VIDEO_BYTES = 500.megabytes
    ProcessingFailed = Class.new(StandardError)

    def initialize
      @api = CallsLinkedinApi.new
      @downloads_media = DownloadsMedia.new
    end

    # Returns the video URN, which LinkedIn processes asynchronously
    def upload(item, access_token:, person_urn:)
      download = @downloads_media.download(item, max_bytes: MAX_VIDEO_BYTES)
      initialized = api!(:post, "rest/videos?action=initializeUpload", access_token:, body: {
        initializeUploadRequest: {owner: person_urn, fileSizeBytes: download.size, uploadCaptions: false, uploadThumbnail: false}
      }).data.fetch("value")
      etags = initialized.fetch("uploadInstructions").map { |instruction| upload_part(download.file, instruction) }
      api!(:post, "rest/videos?action=finalizeUpload", access_token:, body: {
        finalizeUploadRequest: {video: initialized.fetch("video"), uploadToken: initialized["uploadToken"].to_s, uploadedPartIds: etags}
      })

      initialized.fetch("video")
    end

    def available?(video_urn, access_token:)
      video = api!(:get, "rest/videos/#{CGI.escape(video_urn)}", access_token:).data
      raise ProcessingFailed, "LinkedIn failed to process video #{video_urn}: #{video["processingFailureReason"]}" if video["status"] == "PROCESSING_FAILED"

      video["status"] == "AVAILABLE"
    end

    private

    # Parts (read from disk one at a time, since videos can be large) go to pre-signed URLs, which must not be sent the access token
    def upload_part(file, instruction)
      file.seek(instruction.fetch("firstByte"))
      response = HTTParty.put(
        instruction.fetch("uploadUrl"),
        body: file.read(instruction.fetch("lastByte") - instruction.fetch("firstByte") + 1),
        headers: {"Content-Type" => "application/octet-stream"}
      )
      raise "Failed to upload video part to LinkedIn (HTTP #{response.code}). Response: #{response.body}" unless response.success?

      response.headers["etag"]
    end

    def api!(method, path, access_token:, body: nil)
      @api.call(method:, path:, access_token:, body:).tap do |result|
        raise "LinkedIn video API call failed. #{result.message}" unless result.success?
      end
    end
  end
end
