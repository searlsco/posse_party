class Platforms::Bsky
  class SyndicatesBskyPost
    def initialize
      @opens_session = OpensSession.new
      @attaches_web_card = AttachesWebCard.new
      @uploads_images = UploadsImages.new
      @uploads_video = UploadsVideo.new
      @creates_post = CreatesPost.new
      @finishes_video_post = FinishesVideoPost.new
    end

    def syndicate!(crosspost, crosspost_config, crosspost_content, rich_text_facets)
      session = @opens_session.open(crosspost.account)
      post = {"text" => crosspost_content, "facets" => rich_text_facets}.compact
      if (video = crosspost_config.media.find(&:video?))
        syndicate_video!(crosspost, session, post, video)
      else
        record_manager = Bskyrb::RecordManager.new(session)
        embed = if crosspost_config.media.any?
          @uploads_images.upload(crosspost_config.media, session)
        elsif crosspost_config.attach_link
          @attaches_web_card.attach!(crosspost_config, record_manager)
        end
        @creates_post.create(crosspost, session, post.merge("embed" => embed).compact)
      end
    rescue PublishesCrosspost::UnsupportedMediaError
      raise
    rescue Bskyrb::UnauthorizedError => e
      PublishesCrosspost::Result.new(success?: false, message: "Failed to authenticate to Bsky (invalid credentials)", error: e)
    rescue => e
      PublishesCrosspost::Result.new(success?: false, message: "Failed to syndicate to Bsky", error: e)
    end

    private

    # Bsky's video service processes uploads asynchronously, so the post is created once it's done (possibly by finish!)
    def syndicate_video!(crosspost, session, post, video)
      job_id = @uploads_video.upload(video, session)
      crosspost.update!(content: post["text"], metadata: crosspost.metadata.merge(
        "bsky_video_post" => {"post" => post, "url" => video.url, "alt" => video.alt, "job_id" => job_id}
      ))
      @finishes_video_post.finish(crosspost, session:)
    end
  end
end
