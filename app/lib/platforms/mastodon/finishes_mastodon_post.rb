class Platforms::Mastodon
  class FinishesMastodonPost
    # Mastodon refuses statuses whose attachments are still processing, so post once they're all ready
    def finish(crosspost)
      return PublishesCrosspost::Result.new(success?: false, message: "No Mastodon post to finish", unretriable?: true) if (pending = crosspost.metadata["mastodon_post"]).blank?

      base_url = crosspost.account.credentials["base_url"]
      access_token = crosspost.account.credentials["access_token"]
      if pending["media_ids"].all? { |media_id| ready?(media_id, pending, base_url:, access_token:) }
        post!(crosspost, pending, base_url:, access_token:)
      else
        PublishesCrosspost::Result.new(success?: true, needs_to_finish?: true, message: "Mastodon post queued for publishing (waiting for media processing)")
      end
    rescue PublishesCrosspost::UnsupportedMediaError
      raise
    rescue => e
      PublishesCrosspost::Result.new(success?: false, message: "Failed to syndicate to Mastodon", error: e)
    end

    private

    # https://docs.joinmastodon.org/methods/media/#get
    def ready?(media_id, pending, base_url:, access_token:)
      response = HTTParty.get("#{base_url}/api/v1/media/#{media_id}", headers: {"Authorization" => "Bearer #{access_token}"})
      if response.code == 422
        url = pending.fetch("media_urls", {})[media_id]
        raise PublishesCrosspost::UnsupportedMediaError.new(CrosspostMedia.new(url:), "Mastodon failed to process #{url}: #{response.body}")
      end
      raise "Mastodon failed to process media #{media_id} (HTTP #{response.code}). Response: #{response.body}" unless [200, 206].include?(response.code)

      response.code == 200 && response["url"].present?
    end

    def post!(crosspost, pending, base_url:, access_token:)
      response = HTTParty.post(
        "#{base_url}/api/v1/statuses",
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        },
        body: {status: pending["status"], media_ids: pending["media_ids"].presence}.compact.to_json
      )

      if response.success? && (post_id = response.dig("id")).present?
        crosspost.update!(
          remote_id: post_id,
          url: response["url"],
          content: pending["status"],
          status: "published",
          published_at: Now.time
        )
        PublishesCrosspost::Result.new(success?: true)
      else
        PublishesCrosspost::Result.new(
          success?: false,
          message: "Failed to create Mastodon post (HTTP #{response.code}). Response: #{response.body}"
        )
      end
    end
  end
end
