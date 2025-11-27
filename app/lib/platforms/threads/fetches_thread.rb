class Platforms::Threads
  class FetchesThread
    def initialize
      @calls_threads_api = CallsThreadsApi.new
    end

    def fetch(thread_id, access_token:)
      @calls_threads_api.call(
        method: :get,
        path: thread_id,
        query: {
          fields: "permalink",
          access_token:
        }
      )
    end
  end
end
