class Platforms::Threads
  class PublishesThread
    def initialize
      @publishes_container = PublishesContainer.new
      @fetches_thread = FetchesThread.new
    end

    def publish(crosspost, container_id, crosspost_content, access_token:)
      if (publish_result = @publishes_container.publish(container_id, access_token:)).success?
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
        PublishesCrosspost::Result.new(success?: false, message: "Failed to publish Threads container #{container_id}. Error: #{publish_result.message}")
      end
    end
  end
end
