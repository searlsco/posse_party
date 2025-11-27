class Platforms::Youtube
  class DownloadsVideo
    Result = Struct.new(:success?, :message, :file_path, :error, keyword_init: true)

    def download(video_url)
      temp_file = Tempfile.new(["youtube_video", ".mp4"])
      temp_file.binmode

      response = HTTParty.get(video_url, stream_body: true) do |fragment|
        temp_file.write(fragment)
      end

      temp_file.close
      if response.success?
        Result.new(success?: true, file_path: temp_file.path)
      else
        temp_file.unlink
        Result.new(success?: false, message: "Failed to download video: #{response.code}")
      end
    rescue => e
      temp_file&.close
      temp_file&.unlink
      Result.new(success?: false, message: "Exception during video download: #{e.message}", error: e)
    end
  end
end
