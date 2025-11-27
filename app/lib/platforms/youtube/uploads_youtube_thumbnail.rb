class Platforms::Youtube
  class UploadsYoutubeThumbnail
    Result = Struct.new(:success?, :message, :error, keyword_init: true)

    def upload(account, video_id, poster_url)
      return Result.new(success?: true) if poster_url.blank?

      download_response = HTTParty.get(poster_url, format: :plain)
      return Result.new(success?: false, message: "Failed to download thumbnail: #{download_response.code}") unless download_response.success?

      upload_response = HTTParty.post(
        "https://www.googleapis.com/upload/youtube/v3/thumbnails/set?videoId=#{video_id}&uploadType=media",
        headers: {
          "Authorization" => "Bearer #{account.credentials["access_token"]}",
          "Content-Type" => "image/jpeg"
        },
        body: download_response.body,
        format: :plain
      )

      if upload_response.success?
        Result.new(success?: true)
      else
        Result.new(success?: false, message: "Failed to upload thumbnail: #{upload_response.code} - #{upload_response.body}")
      end
    rescue => e
      Result.new(success?: false, message: "Exception during thumbnail upload: #{e.message}", error: e)
    end
  end
end
