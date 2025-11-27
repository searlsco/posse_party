class Platforms::Linkedin
  class UploadsImage
    def upload(image_url, upload_url, access_token:)
      return Outcome.failure("Image URL is required") if image_url.blank?
      return Outcome.failure("Upload URL is required") if upload_url.blank?

      if (image_data = download_image(image_url)).present?
        response = HTTParty.put(
          upload_url,
          headers: {
            "Authorization" => "Bearer #{access_token}",
            "Content-Type" => "image/jpeg"
          },
          body: image_data
        )

        if response.success?
          Outcome.success
        else
          Outcome.failure("Failed to upload image to LinkedIn. Response: #{response.parsed_response || response.body}")
        end
      else
        Outcome.failure("Failed to download image from #{image_url}")
      end
    end

    private

    def download_image(image_url)
      response = HTTParty.get(image_url)
      response.body if response.success?
    end
  end
end
