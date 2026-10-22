class Platforms::Bsky
  # https://docs.bsky.app/docs/tutorials/video
  class UploadsVideo
    VIDEO_SERVICE_URL = "https://video.bsky.app"
    MAX_VIDEO_BYTES = 100.megabytes
    JobStatus = Struct.new(:job_id, :blob, :failure, keyword_init: true)

    def initialize
      @downloads_media = DownloadsMedia.new
    end

    # Returns the job ID for the video service's processing of the upload
    def upload(item, session)
      download = @downloads_media.download(item, max_bytes: MAX_VIDEO_BYTES)
      response = HTTParty.post(
        "#{VIDEO_SERVICE_URL}/xrpc/app.bsky.video.uploadVideo",
        query: {did: session.did, name: "#{Digest::SHA256.hexdigest(item.url)[0, 16]}.mp4"},
        body: download.bytes,
        headers: {"Authorization" => "Bearer #{service_token(session)}", "Content-Type" => "video/mp4"}
      )
      job_status = to_job_status(response.parsed_response) if response.parsed_response.is_a?(Hash)
      if job_status&.job_id.present? && job_status.failure.nil?
        job_status.job_id
      elsif job_status&.failure && [200, 400, 413, 415, 422].include?(response.code)
        raise PublishesCrosspost::UnsupportedMediaError.new(item, "Bsky refused video #{item.url}: #{job_status.failure}")
      else
        # Authorization trouble, rate limiting, or an outage: retry with the video
        raise "Failed to upload video #{item.url} to Bsky (HTTP #{response.code}). Response: #{response.body}"
      end
    end

    def status(job_id)
      to_job_status(HTTParty.get("#{VIDEO_SERVICE_URL}/xrpc/app.bsky.video.getJobStatus", query: {jobId: job_id}).parsed_response)
    end

    private

    # Uploads are authorized by a service token minted by the account's own PDS
    def service_token(session)
      pds_host = URI(DIDKit::Resolver.new.resolve_did(session.did).pds_endpoint).host
      response = HTTParty.get(
        "#{session.pds}/xrpc/com.atproto.server.getServiceAuth",
        query: {aud: "did:web:#{pds_host}", lxm: "com.atproto.repo.uploadBlob", exp: (Now.time + 30.minutes).to_i},
        headers: {"Authorization" => "Bearer #{session.access_token}"}
      )
      raise "Failed to get Bsky service auth token. Response: #{response.body}" unless response.success?

      response["token"]
    end

    # uploadVideo responds with a bare job status, getJobStatus wraps it in "jobStatus"
    def to_job_status(body)
      job_status = (body.is_a?(Hash) && body["jobStatus"]) || body || {}
      JobStatus.new(
        job_id: job_status["jobId"],
        blob: job_status["blob"],
        failure: ([job_status["error"], job_status["message"]].compact.join(": ").presence if failed?(job_status))
      )
    end

    # "already_exists" just means the same video was processed before, and its job still yields the blob
    def failed?(job_status)
      job_status["blob"].nil? && job_status["error"] != "already_exists" &&
        (job_status["state"] == "JOB_STATE_FAILED" || job_status["error"].present?)
    end
  end
end
