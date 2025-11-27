class Platforms::Linkedin
  class InitiatesImageUpload
    Result = Struct.new(:success?, :upload_url, :image_urn, :message)

    def initialize
      @api = CallsLinkedinApi.new
    end

    def initiate(access_token:, person_urn:)
      response = @api.call(
        method: :post,
        path: "rest/images?action=initializeUpload",
        body: {
          initializeUploadRequest: {
            owner: person_urn
          }
        },
        access_token: access_token
      )

      if response.success? && response.data&.dig("value").present?
        value = response.data["value"]
        Result.new(
          success?: true,
          upload_url: value["uploadUrl"],
          image_urn: value["image"]
        )
      else
        Result.new(
          success?: false,
          message: "Failed to initiate LinkedIn image upload. #{response.message}"
        )
      end
    end
  end
end
