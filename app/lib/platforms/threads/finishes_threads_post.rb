class Platforms::Threads
  class FinishesThreadsPost
    class ProcessingError < StandardError
      def initialize(container_id, message)
        @container_id = container_id
        super(message)
      end

      attr_reader :container_id
    end

    def initialize
      @calls_threads_api = CallsThreadsApi.new
      @creates_media_container = CreatesMediaContainer.new
      @publishes_thread = PublishesThread.new
    end

    def finish(crosspost)
      return PublishesCrosspost::Result.new(success?: false, message: "No Threads post to finish", unretriable?: true) if (pending = crosspost.metadata["threads_post"]).blank?

      access_token = crosspost.account.credentials["access_token"]
      if pending["container_id"].present?
        publish_when_ready(crosspost, pending["container_id"], access_token:)
      elsif pending["child_ids"].all? { |child_id| ready?(child_id, access_token:) }
        create_carousel!(crosspost, pending, access_token:)
        finish(crosspost)
      else
        waiting
      end
    rescue ProcessingError => e
      if (url = pending.fetch("media_urls", {})[e.container_id])
        raise PublishesCrosspost::UnsupportedMediaError.new(CrosspostMedia.new(url:), e.message)
      else
        # The carousel container itself failing can't be pinned on any one item
        PublishesCrosspost::Result.new(success?: false, message: "Threads couldn't process the carousel", error: e, unretriable?: true)
      end
    rescue PublishesCrosspost::UnsupportedMediaError
      raise
    rescue => e
      PublishesCrosspost::Result.new(success?: false, message: "An unexpected error occurred while crossposting to Threads", error: e)
    end

    private

    def publish_when_ready(crosspost, container_id, access_token:)
      if ready?(container_id, access_token:)
        @publishes_thread.publish(crosspost, container_id, crosspost.content, access_token:)
      else
        waiting
      end
    end

    def create_carousel!(crosspost, pending, access_token:)
      result = @creates_media_container.create_carousel(pending["child_ids"], access_token:, text: crosspost.content)
      raise "Failed to create Threads carousel container. Error: #{result.message}" unless result.success?

      crosspost.update!(metadata: crosspost.metadata.merge("threads_post" => pending.merge("container_id" => result.id)))
    end

    # https://developers.facebook.com/docs/threads/troubleshooting#publishing-does-not-return-a-media-id
    def ready?(container_id, access_token:)
      result = @calls_threads_api.call(method: :get, path: container_id, query: {fields: "status,error_message", access_token:})
      raise "Failed to check status of Threads container #{container_id}. Error: #{result.message}" unless result.success?

      case result.data[:status]
      when "FINISHED" then true
      when "IN_PROGRESS" then false
      else raise ProcessingError.new(container_id, "Threads couldn't process container #{container_id} (#{result.data[:status]}): #{result.data[:error_message]}")
      end
    end

    def waiting
      PublishesCrosspost::Result.new(success?: true, needs_to_finish?: true, message: "Threads post queued for publishing (waiting for media processing)")
    end
  end
end
