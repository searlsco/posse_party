class FetchesFeed
  def initialize
    @gets_http_url = GetsHttpUrl.new
    @parses_feed = ParsesFeed.new
    @asks_if_anything_changed = AsksIfAnythingChanged.new
    @persists_feed = PersistsFeed.new
    @creates_crossposts = CreatesCrossposts.new
    @determines_newest_known_post = DeterminesNewestKnownPost.new
  end

  def fetch!(feed, cache: true)
    first_ever_fetch = feed.last_checked_at.nil?
    previous_last_checked_at = feed.last_checked_at
    skip_posts_older_than = @determines_newest_known_post.timestamp_for(feed)
    response = @gets_http_url.get(feed.url, headers: cache ? {
      "If-None-Match" => feed.etag_header,
      "If-Modified-Since" => feed.last_modified_header
    }.compact : {})
    return if response.code == 304 # Unchanged

    parsed_feed = @parses_feed.parse(response.body)

    time_before_persist = Now.time
    something_changed = @asks_if_anything_changed.ask(feed.posts) do
      @persists_feed.persist(
        feed,
        parsed_feed,
        etag_header: response.headers["etag"],
        last_modified_header: response.headers["last-modified"]
      )
    end
    if something_changed
      @creates_crossposts.create!(
        feed,
        published_after: (first_ever_fetch ? nil : previous_last_checked_at),
        skip_posts_older_than: skip_posts_older_than
      )

      if feed.user
        new_count = feed.posts.where("posts.created_at >= ?", time_before_persist).count

        NotifiesUser.new.notify(
          user: feed.user,
          title: "Feed \"#{feed.notification_label}\" updated (#{new_count} new)",
          severity: "info",
          text: "See below for updated posts and crossposts",
          refs: ([{"model" => "Feed", "id" => feed.id}] +
            feed.posts.where("posts.updated_at >= ?", time_before_persist).pluck(:id).map { |pid| {"model" => "Post", "id" => pid} } +
            feed.crossposts.where("crossposts.updated_at >= ?", time_before_persist).pluck(:id).map { |cid| {"model" => "Crosspost", "id" => cid} })
        )
      end
    end
  end

  private
end
