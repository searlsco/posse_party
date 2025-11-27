class Platforms::Youtube
  class UploadsYoutubeVideo
    UploadUrlResult = Struct.new(:success?, :message, :upload_url, keyword_init: true)
    Result = Struct.new(:success?, :message, :video_id, :error, keyword_init: true)

    def upload(account, local_path, title, description)
      upload_result = request_upload_url(account, local_path, title, description)
      if upload_result.success?
        upload_video_bytes(account, upload_result.upload_url, local_path)
      else
        Result.new(success?: false, message: "Failed to start upload: #{upload_result.message}")
      end
    end

    private

    def request_upload_url(account, local_path, title, description)
      file_size = File.size(local_path)

      response = HTTParty.post(
        "https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status",
        headers: {
          "Authorization" => "Bearer #{account.credentials["access_token"]}",
          "Content-Type" => "application/json; charset=UTF-8",
          "X-Upload-Content-Type" => "video/*",
          "X-Upload-Content-Length" => file_size.to_s
        },
        body: {
          snippet: {
            title: title,
            description: description,
            categoryId: 22
          },
          status: {
            privacyStatus: "public",
            selfDeclaredMadeForKids: false
          }
        }.to_json,
        format: :plain
      )

      if response.success? && response.headers["location"]
        UploadUrlResult.new(success?: true, upload_url: response.headers["location"])
      else
        error_data = RelaxedJson.parse(response.body)
        error_hash = error_data[:error] || error_data["error"]
        error_message = if error_data && error_hash
          error_msg = error_hash[:message] || error_hash["message"] || error_hash
          "#{response.code} - #{error_msg}"
        else
          "#{response.code} - #{response.body}"
        end
        UploadUrlResult.new(success?: false, message: error_message)
      end
    end

    def upload_video_bytes(account, upload_url, local_path)
      file = File.open(local_path, "rb")
      file_size = file.size

      response = HTTParty.put(
        upload_url,
        headers: {
          "Authorization" => "Bearer #{account.credentials["access_token"]}",
          "Content-Type" => "video/*",
          "Content-Length" => file_size.to_s
        },
        body: file.read
      )

      file.close

      data = RelaxedJson.parse(response.body)
      video_id = data[:id] || data["id"]

      if (response.code == 200 || response.code == 201) && video_id
        Result.new(success?: true, video_id: video_id)
      else
        Result.new(success?: false, message: "Failed to upload video bytes: #{response.code} - #{response.body}")
      end
    rescue => e
      file&.close
      Result.new(success?: false, message: "Exception during video upload: #{e.message}", error: e)
    end
  end
end
