class Platforms::Mastodon
  class SyndicatesMastodonPost
    def syndicate!(crosspost, crosspost_content)
      client = Mastodon::REST::Client.new(
        base_url: crosspost.account.credentials["base_url"],
        bearer_token: crosspost.account.credentials["access_token"]
      )
      response = client.create_status(crosspost_content)

      if (post_id = response&.id).blank?
        PublishesCrosspost::Result.new(success?: false, message: "Failed to create Mastodon post. Response: #{response}")
      else
        crosspost.update!(
          remote_id: post_id,
          url: response.url,
          content: crosspost_content,
          status: "published",
          published_at: Now.time
        )
        PublishesCrosspost::Result.new(success?: true)
      end
    rescue => e
      PublishesCrosspost::Result.new(success?: false, message: "Failed to syndicate to Mastodon", error: e)
    end
  end
end
