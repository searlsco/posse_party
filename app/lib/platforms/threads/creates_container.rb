class Platforms::Threads
  class CreatesContainer
    def initialize
      @calls_threads_api = CallsThreadsApi.new
    end

    def create(crosspost_content, crosspost_config, access_token:)
      @calls_threads_api.call(
        method: :post,
        path: "me/threads",
        query: {
          text: crosspost_content,
          media_type: "TEXT",
          link_attachment: (crosspost_config.url if crosspost_config.attach_link && crosspost_config.url.present?),
          access_token:
        }
      ).tap do |result|
        raise PublishesCrosspost::RecoverableLinkAttachmentError if result.invalid_link_attachment?
      end
    end
  end
end
