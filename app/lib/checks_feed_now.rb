class ChecksFeedNow
  def initialize
    @fetches_feed = FetchesFeed.new
  end

  def check(feed:, cache: false)
    before_total = feed.posts.count

    @fetches_feed.fetch!(feed, cache: cache).tap { feed.reload }

    Result.success({
      new_post_count: [feed.posts.count - before_total, 0].max
    })
  rescue => e
    Result.failure(error_message_for(e))
  end

  private

  def error_message_for(error)
    msg = error.message.to_s.strip
    case error
    when SocketError
      "Connection failed: #{msg}"
    else
      if defined?(Feedjira) && error.class.name.start_with?("Feedjira")
        "Feed parsing failed: #{msg}"
      else
        "Feed check failed: #{msg}"
      end
    end
  end
end
