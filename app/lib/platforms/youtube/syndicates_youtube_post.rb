class Platforms::Youtube
  class SyndicatesYoutubePost
    def initialize
      @refreshes_youtube_access_token = RefreshesYoutubeAccessToken.new
      @downloads_video = DownloadsVideo.new
      @uploads_youtube_video = UploadsYoutubeVideo.new
      @uploads_youtube_thumbnail = UploadsYoutubeThumbnail.new
    end

    def syndicate!(crosspost, crosspost_config, crosspost_content)
      return PublishesCrosspost::Result.new(success?: false, message: "No media found") if crosspost.post.media.empty?
      return PublishesCrosspost::Result.new(success?: false, message: "YouTube requires exactly one video") if crosspost.post.media.count != 1
      return PublishesCrosspost::Result.new(success?: false, message: "YouTube requires video content") if crosspost.post.media.first["url"].blank?

      refresh_result = @refreshes_youtube_access_token.refresh(crosspost.account)
      if refresh_result.success?
        download_result = @downloads_video.download(crosspost.post.media.first["url"])
        if download_result.success?
          upload_result = @uploads_youtube_video.upload(
            crosspost.account,
            download_result.file_path,
            crosspost.post.title.truncate(100),
            "See the full post at #{crosspost.post.url}\n\n#Shorts"
          )
          File.delete(download_result.file_path) if File.exist?(download_result.file_path)

          if upload_result.success?
            @uploads_youtube_thumbnail.upload(
              crosspost.account,
              upload_result.video_id,
              crosspost.post.media.first["poster_url"]
            )

            crosspost.update!(
              remote_id: upload_result.video_id,
              url: "https://www.youtube.com/watch?v=#{upload_result.video_id}",
              content: crosspost_content,
              status: "published",
              published_at: Now.time
            )
            PublishesCrosspost::Result.new(success?: true)
          else
            PublishesCrosspost::Result.new(success?: false, message: "Failed to upload video: #{upload_result.message}")
          end
        else
          PublishesCrosspost::Result.new(success?: false, message: "Failed to download video: #{download_result.message}")
        end
      else
        PublishesCrosspost::Result.new(success?: false, message: "Failed to refresh access token: #{refresh_result.message}")
      end
    rescue => e
      File.delete(download_result.file_path) if download_result&.file_path && File.exist?(download_result.file_path)
      PublishesCrosspost::Result.new(success?: false, message: "An unexpected error occurred while crossposting to YouTube", error: e)
    end
  end
end
