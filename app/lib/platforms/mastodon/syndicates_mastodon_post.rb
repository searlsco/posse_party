class Platforms::Mastodon
  class SyndicatesMastodonPost
    def syndicate!(crosspost, crosspost_content)
      base_url = crosspost.account.credentials["base_url"]
      access_token = crosspost.account.credentials["access_token"]

      response = HTTParty.post(
        "#{base_url}/api/v1/statuses",
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        },
        body: { status: crosspost_content }.to_json
      )

      if response.success? && (post_id = response.dig("id")).present?
        crosspost.update!(
          remote_id: post_id,
          url: response["url"],
          content: crosspost_content,
          status: "published",
          published_at: Now.time
        )
        PublishesCrosspost::Result.new(success?: true)
      else
        PublishesCrosspost::Result.new(success?: false, message: "Failed to create Mastodon post. Response: #{response.body}")
      end
    rescue => e
      PublishesCrosspost::Result.new(success?: false, message: "Failed to syndicate to Mastodon", error: e)
    end
  end
end
