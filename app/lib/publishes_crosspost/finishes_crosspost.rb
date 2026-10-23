class PublishesCrosspost
  class FinishesCrosspost
    def initialize
      @matches_platform_api = MatchesPlatformApi.new
      @tracks_crosspost_status = TracksCrosspostStatus.new
      @rejects_media = RejectsMedia.new
      @publishes_crosspost = PublishesCrosspost.new
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

    # Replan within the current attempt so even the final attempt can use its media fallback.
    def finish(crosspost, api)
      api.finish!(crosspost)
    rescue UnsupportedMediaError => e
      @rejects_media.reject(crosspost, e.media)
      @publishes_crosspost.replan(crosspost, api)
    end
  end
end
