class Platforms::Linkedin
  class CallsLinkedinApi
    Result = Struct.new(:success?, :data, :headers, :message)

    def call(method:, path:, access_token:, body: nil)
      url = Platforms::Linkedin::API_BASE_URL + path
      options = {
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "LinkedIn-Version" => "202505",
          "X-Restli-Protocol-Version" => "2.0.0"
        }
      }

      if body.present?
        options[:headers]["Content-Type"] = "application/json"
        options[:body] = body.to_json
      end

      response = HTTParty.send(method, url, options)

      if response.success?
        Result.new(success?: true, data: response.parsed_response, headers: response.headers)
      else
        Result.new(success?: false, data: response.parsed_response, headers: response.headers, message: <<~MSG)
          Error calling LinkedIn API.

          Response:
          #{response.parsed_response || response.body}

          Request:
          URL: #{url}
          Method: #{method.upcase}
          Headers: #{options[:headers].inspect}
        MSG
      end
    rescue => e
      Result.new(success?: false, message: "Unexpected error calling LinkedIn API: #{e.message}")
    end
  end
end
