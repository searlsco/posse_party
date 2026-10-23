class Platforms::Threads
  # https://developers.facebook.com/docs/threads/posts
  class CreatesMediaContainer
    def initialize
      @calls_threads_api = CallsThreadsApi.new
    end

    # A single image or video post carries the text itself. Carousel items don't; the text goes on the carousel container
    def create(item, access_token:, text: nil, carousel_item: false)
      @calls_threads_api.call(
        method: :post,
        path: "me/threads",
        query: {
          media_type: item.video? ? "VIDEO" : "IMAGE",
          image_url: (item.url unless item.video?),
          video_url: (item.url if item.video?),
          alt_text: item.alt.presence,
          is_carousel_item: (true if carousel_item),
          text: text,
          access_token:
        }.compact
      )
    end

    def create_carousel(child_ids, access_token:, text:)
      @calls_threads_api.call(
        method: :post,
        path: "me/threads",
        query: {media_type: "CAROUSEL", children: child_ids.join(","), text:, access_token:}
      )
    end
  end
end
