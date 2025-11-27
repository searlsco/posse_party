class Platforms::Threads
  class SyndicatesThreadsPost
    def initialize
      @creates_container = CreatesContainer.new
      @publishes_container = PublishesContainer.new
      @fetches_thread = FetchesThread.new
    end

    def syndicate!(crosspost, crosspost_config, crosspost_content)
      access_token = crosspost.account.credentials["access_token"]
      if (create_result = @creates_container.create(crosspost_content, crosspost_config, access_token:)).success?
        if (publish_result = @publishes_container.publish(create_result.id, access_token:)).success?
          fetch_result = @fetches_thread.fetch(publish_result.id, access_token:)
          crosspost.update!(
            remote_id: publish_result.id,
            url: (fetch_result.data[:permalink] if fetch_result.success?),
            content: crosspost_content,
            status: "published",
            published_at: Now.time
          )
          PublishesCrosspost::Result.new(
            success?: true,
            message: ("Failed to fetch Thread object for thread with ID #{publish_result.id}. Extremely strange for this to fail (connection error?). Updated crosspost with remote ID but without remote URL. Error: #{fetch_result.message}" unless fetch_result.success?)
          )
        else
          PublishesCrosspost::Result.new(success?: false, message: "Failed to publish Threads container #{create_result.id}. Error: #{publish_result.message}")
        end
      else
        PublishesCrosspost::Result.new(success?: false, message: "Failed to create Threads container. Error: #{create_result.message}")
      end
    rescue PublishesCrosspost::RecoverableError
      raise
    rescue => e
      PublishesCrosspost::Result.new(success?: false, message: "An unexpected error occurred while crossposting to Threads", error: e)
    end
  end
end
