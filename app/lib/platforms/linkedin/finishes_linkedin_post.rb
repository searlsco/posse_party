class Platforms::Linkedin
  class FinishesLinkedinPost
    def initialize
      @uploads_video = UploadsVideo.new
      @publishes_post = PublishesPost.new
    end

    # LinkedIn videos can't be posted until they're processed
    def finish(crosspost)
      return PublishesCrosspost::Result.new(success?: false, message: "No LinkedIn post to finish", unretriable?: true) if (pending = crosspost.metadata["linkedin_post"]).blank?

      access_token = crosspost.account.credentials["access_token"]
      if pending["video_urn"].blank? || @uploads_video.available?(pending["video_urn"], access_token:)
        publish!(crosspost, pending, access_token:)
      else
        PublishesCrosspost::Result.new(success?: true, needs_to_finish?: true, message: "LinkedIn post queued for publishing (waiting for video processing)")
      end
    rescue UploadsVideo::ProcessingFailed => e
      raise PublishesCrosspost::UnsupportedMediaError.new(CrosspostMedia.new(url: pending["video_url"]), e.message)
    rescue => e
      PublishesCrosspost::Result.new(success?: false, message: "An unexpected error occurred while crossposting to LinkedIn", error: e)
    end

    private

    def publish!(crosspost, pending, access_token:)
      if (publish_result = @publishes_post.publish_content(pending["commentary"], pending["content"].deep_symbolize_keys, access_token:, person_urn: crosspost.account.credentials["person_urn"])).success?
        crosspost.update!(
          remote_id: publish_result.post_urn,
          url: publish_result.url,
          status: "published",
          published_at: Now.time
        )
        PublishesCrosspost::Result.new(success?: true)
      else
        PublishesCrosspost::Result.new(success?: false, message: "Failed to publish LinkedIn post. Error: #{publish_result.message}")
      end
    end
  end
end
