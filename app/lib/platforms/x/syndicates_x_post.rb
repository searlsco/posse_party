class Platforms::X
  class SyndicatesXPost
    def initialize
      @uploads_media = UploadsMedia.new
    end

    def syndicate!(crosspost, crosspost_config, crosspost_content)
      # https://github.com/sferik/x-ruby
      client = X::Client.new(
        api_key: crosspost.account.credentials["api_key"],
        api_key_secret: crosspost.account.credentials["api_key_secret"],
        access_token: crosspost.account.credentials["access_token"],
        access_token_secret: crosspost.account.credentials["access_token_secret"]
      )
      username = client.get("users/me").dig("data", "username")
      media_ids = crosspost_config.media.map { |item| @uploads_media.upload(item, client) }
      response = client.post("tweets", {text: crosspost_content, media: ({media_ids:} if media_ids.any?)}.compact.to_json)

      if (post_id = response.dig("data", "id")).nil?
        PublishesCrosspost::Result.new(success?: false, message: "Failed to create X post. Response: #{response}")
      else
        crosspost.update!(
          remote_id: post_id,
          url: "https://x.com/#{username}/status/#{post_id}",
          content: crosspost_content,
          status: "published",
          published_at: Now.time
        )
        PublishesCrosspost::Result.new(success?: true)
      end
    rescue PublishesCrosspost::UnsupportedMediaError
      raise
    rescue => e
      PublishesCrosspost::Result.new(success?: false, message: "Failed to syndicate to X", error: e)
    end
  end
end
