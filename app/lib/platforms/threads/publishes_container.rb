class Platforms::Threads
  class PublishesContainer
    def initialize
      @calls_threads_api = CallsThreadsApi.new
    end

    def publish(container_id, access_token:)
      @calls_threads_api.call(
        method: :post,
        path: "me/threads_publish",
        query: {
          creation_id: container_id,
          access_token:
        }
      ).tap do |result|
        raise PublishesCrosspost::RecoverableLinkAttachmentError if result.invalid_link_attachment?
      end
    end
  end
end
