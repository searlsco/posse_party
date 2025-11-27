class Platforms::Instagram
  class CallsInstagramApi
    Result = Struct.new(:success?, :data, :message) do
      def id
        data&.dig(:id)
      end

      # Convenience accessors for common error fields returned by the Graph API
      def error_code
        data&.dig(:error, :code)
      end

      def error_subcode
        data&.dig(:error, :error_subcode)
      end

      def error_type
        data&.dig(:error, :type)
      end

      def fbtrace_id
        data&.dig(:error, :fbtrace_id)
      end
    end

    def call(method:, path:, query: {})
      url = API_BASE_URL + path
      response = HTTParty.send(method, url, query: query, format: :plain)
      json = RelaxedJson.parse(response)
      if json.present? && json.is_a?(Hash) && json[:error].blank?
        Result.new(success?: true, data: json)
      else
        Result.new(success?: false, data: json, message: <<~MSG)
          Error calling Instagram API.

          Response:
          #{JSON.pretty_generate(json || {})}

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
