class Platforms::Threads
  class CallsThreadsApi
    Result = Struct.new(:success?, :data, :message) do
      def id
        data&.dig(:id)
      end

      # Threads-specific edge case. If a URL is localhost or otherwise not a "real" place from Threads' perspective, it'll barf when createing the container
      def invalid_link_attachment?
        !success? && data&.dig(:error).present? &&
          (
            # Raised during creation when link_attachment is perceived as an invalid domain (e.g. localhost)
            data.dig(:error, :message)&.include?("parameter link_attachment is not a valid URL") ||
            # Raised during publish when Threads barfs while fetching opengraph data. Happens EXTREMELY frequently
            (data.dig(:error, :code) == -1 && data.dig(:error, :error_subcode) == 4279047)
          )
      end
    end

    def call(method:, path:, query:)
      url = API_BASE_URL + path
      response = HTTParty.send(method, url, query: query, format: :plain)
      json = RelaxedJson.parse(response)
      if json.present? && json.is_a?(Hash) && json[:error].blank?
        Result.new(success?: true, data: json)
      else
        Result.new(success?: false, data: json, message: <<~MSG)
          Error calling Threads API.

          Response:
          #{json&.dig(:error).present? ? JSON.pretty_generate(json[:error]) : response.inspect}

          Request:
          URL: #{url}
          Method: #{method.upcase}
          Query:
          #{query.present? ? JSON.pretty_generate(query) : query.inspect}
        MSG
      end
    end
  end
end
