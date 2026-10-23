class Platforms::Mastodon
  class SyndicatesMastodonPost
    def initialize
      @uploads_media = UploadsMedia.new
      @finishes_mastodon_post = FinishesMastodonPost.new
    end

    def syndicate!(crosspost, crosspost_config, crosspost_content)
      credentials = crosspost.account.credentials
      media_urls = crosspost_config.media.to_h { |item|
        [@uploads_media.upload(item, base_url: credentials["base_url"], access_token: credentials["access_token"]), item.url]
      }
      crosspost.update!(content: crosspost_content, metadata: crosspost.metadata.merge(
        "mastodon_post" => {"status" => crosspost_content, "media_ids" => media_urls.keys, "media_urls" => media_urls}
      ))
      @finishes_mastodon_post.finish(crosspost)
    rescue PublishesCrosspost::UnsupportedMediaError, PublishesCrosspost::UnretriableError
      raise
    rescue => e
      PublishesCrosspost::Result.new(success?: false, message: "Failed to syndicate to Mastodon", error: e)
    end
  end
end
