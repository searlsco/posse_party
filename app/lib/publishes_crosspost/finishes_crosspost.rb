class PublishesCrosspost
  class FinishesCrosspost
    def initialize
      @matches_platform_api = MatchesPlatformApi.new
      @tracks_crosspost_status = TracksCrosspostStatus.new
      @rejects_media = RejectsMedia.new
    end

    def publish(crosspost_id)
      crosspost = Crosspost.includes(:account, :post).find(crosspost_id)
      return PublishesCrosspost::Result.new(success?: true, message: "Not the WIP crosspost for the account") unless crosspost.wip?
      @tracks_crosspost_status.track(crosspost) do
        api = @matches_platform_api.match(crosspost.account)
        if api.finishable?
          finish(crosspost, api)
        else
          PublishesCrosspost::Result.new(success?: false, message: "Platform doesn't support finishing (this is a bug)", unretriable?: true)
        end
      end
    end

    private

    # Media can fail the platform's processing after it was uploaded. Publishing starts over (as a
    # retry) planning without it, so media_fallback decides what becomes of the post
    def finish(crosspost, api)
      api.finish!(crosspost)
    rescue UnsupportedMediaError => e
      @rejects_media.reject(crosspost, e.media)
      PublishesCrosspost::Result.new(success?: false, message: "#{e.message}. Publishing again without it", error: e)
    end
  end
end
