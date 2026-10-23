class Platforms::Bsky
  class CreatesPost
    def create(crosspost, session, post)
      record = {
        "collection" => "app.bsky.feed.post",
        "$type" => "app.bsky.feed.post",
        "repo" => session.did,
        "record" => {
          "$type" => "app.bsky.feed.post",
          "createdAt" => Now.time.iso8601(3)
        }.merge(post)
      }
      result = Bskyrb::RecordManager.new(session).create_record(record)
      if result["error"].present?
        raise "Failed to create Bsky post: #{result["error"]} - #{result["message"]}. Record we sent follows: #{record.inspect}"
      elsif (uri = result["uri"]).nil?
        PublishesCrosspost::Result.new(success?: false, message: "Failed to create Bsky post")
      else
        # Recorded before anything else can fail, so a retry never posts it again
        crosspost.update!(remote_id: uri, content: post["text"], status: "published", published_at: Now.time)
        crosspost.update!(url: uri_to_url(uri, session))
        PublishesCrosspost::Result.new(success?: true)
      end
    end

    private

    def uri_to_url(uri, session)
      bsky_handle = DIDKit::Resolver.new.get_verified_handle(session.did)
      post_id = uri[/[^\/]+$/]
      "https://bsky.app/profile/#{bsky_handle}/post/#{post_id}"
    end
  end
end
