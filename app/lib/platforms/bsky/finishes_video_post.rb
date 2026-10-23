class Platforms::Bsky
  class FinishesVideoPost
    def initialize
      @opens_session = OpensSession.new
      @uploads_video = UploadsVideo.new
      @creates_post = CreatesPost.new
    end

    def finish(crosspost, session: nil)
      return PublishesCrosspost::Result.new(success?: false, message: "No Bsky video upload to finish", unretriable?: true) if (pending = crosspost.metadata["bsky_video_post"]).blank?

      job_status = @uploads_video.status(pending["job_id"])
      if job_status.blob
        @creates_post.create(crosspost, session || @opens_session.open(crosspost.account), pending["post"].merge(
          "embed" => {"$type" => "app.bsky.embed.video", "video" => job_status.blob, "alt" => pending["alt"]}.compact
        ))
      elsif job_status.failure
        raise PublishesCrosspost::UnsupportedMediaError.new(CrosspostMedia.new(url: pending["url"]), "Bsky failed to process video #{pending["url"]}: #{job_status.failure}")
      else
        PublishesCrosspost::Result.new(success?: true, needs_to_finish?: true, message: "Bsky video queued for publishing (waiting for processing)")
      end
    end
  end
end
