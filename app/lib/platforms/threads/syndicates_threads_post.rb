class Platforms::Threads
  class SyndicatesThreadsPost
    def initialize
      @creates_container = CreatesContainer.new
      @creates_media_container = CreatesMediaContainer.new
      @publishes_thread = PublishesThread.new
      @finishes_threads_post = FinishesThreadsPost.new
    end

    def syndicate!(crosspost, crosspost_config, crosspost_content)
      access_token = crosspost.account.credentials["access_token"]
      if crosspost_config.media.any?
        syndicate_media!(crosspost, crosspost_config.media, crosspost_content, access_token:)
      elsif (create_result = @creates_container.create(crosspost_content, crosspost_config, access_token:)).success?
        @publishes_thread.publish(crosspost, create_result.id, crosspost_content, access_token:)
      else
        PublishesCrosspost::Result.new(success?: false, message: "Failed to create Threads container. Error: #{create_result.message}")
      end
    rescue PublishesCrosspost::RecoverableError, PublishesCrosspost::UnsupportedMediaError
      raise
    rescue => e
      PublishesCrosspost::Result.new(success?: false, message: "An unexpected error occurred while crossposting to Threads", error: e)
    end

    private

    # Threads fetches media from its URL and processes it asynchronously, so containers are published once they're ready.
    # A lone item becomes an image or video post. Several become a carousel, which can only be created once every item is ready
    def syndicate_media!(crosspost, media, crosspost_content, access_token:)
      pending = if media.one?
        container_id = create!(media.first, access_token:, text: crosspost_content)
        {"container_id" => container_id, "media_urls" => {container_id => media.first.url}}
      else
        media_urls = media.to_h { |item| [create!(item, access_token:, carousel_item: true), item.url] }
        {"child_ids" => media_urls.keys, "media_urls" => media_urls}
      end
      crosspost.update!(content: crosspost_content, metadata: crosspost.metadata.merge("threads_post" => pending))
      @finishes_threads_post.finish(crosspost)
    end

    # Only an invalid parameter (code 100) means Threads refused the media itself. Anything else
    # (an expired token, rate limiting, an outage) should be retried with the media
    def create!(item, access_token:, **options)
      result = @creates_media_container.create(item, access_token:, **options)
      if result.success?
        result.id
      elsif result.data&.dig(:error, :code) == 100
        raise PublishesCrosspost::UnsupportedMediaError.new(item, "Threads refused #{item.url}: #{result.message}")
      else
        raise "Failed to create Threads container for #{item.url}. Error: #{result.message}"
      end
    end
  end
end
