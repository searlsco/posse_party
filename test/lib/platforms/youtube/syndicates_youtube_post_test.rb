require "test_helper"

class Platforms::Youtube::SyndicatesYoutubePostTest < ActiveSupport::TestCase
  def test_uses_poster_url_to_upload_thumbnail
    refreshes_youtube_access_token = Mocktail.of_next(Platforms::Youtube::RefreshesYoutubeAccessToken)
    downloads_video = Mocktail.of_next(Platforms::Youtube::DownloadsVideo)
    uploads_youtube_video = Mocktail.of_next(Platforms::Youtube::UploadsYoutubeVideo)
    uploads_youtube_thumbnail = Mocktail.of_next(Platforms::Youtube::UploadsYoutubeThumbnail)
    subject = Platforms::Youtube::SyndicatesYoutubePost.new

    post = posts(:user_post)
    post.update!(media: [
      {
        "type" => "video",
        "url" => "https://example.com/video.mp4",
        "poster_url" => "https://example.com/poster.jpg"
      }
    ])
    crosspost = Crosspost.create!(
      post: post,
      account: accounts(:user_youtube_account),
      status: "ready",
      content: "Some content"
    )

    stubs { refreshes_youtube_access_token.refresh(crosspost.account) }.with {
      Outcome.success
    }
    stubs { downloads_video.download("https://example.com/video.mp4") }.with {
      Platforms::Youtube::DownloadsVideo::Result.new(success?: true, file_path: "/tmp/video.mp4")
    }
    stubs {
      uploads_youtube_video.upload(
        crosspost.account,
        "/tmp/video.mp4",
        crosspost.post.title.truncate(100),
        "See the full post at #{crosspost.post.url}\n\n#Shorts"
      )
    }.with {
      Platforms::Youtube::UploadsYoutubeVideo::Result.new(success?: true, video_id: "VIDEO123")
    }
    stubs {
      uploads_youtube_thumbnail.upload(
        crosspost.account,
        "VIDEO123",
        "https://example.com/poster.jpg"
      )
    }.with {
      Platforms::Youtube::UploadsYoutubeThumbnail::Result.new(success?: true)
    }

    result = subject.syndicate!(crosspost, nil, "Some content")

    assert result.success?
    verify {
      uploads_youtube_thumbnail.upload(
        crosspost.account,
        "VIDEO123",
        "https://example.com/poster.jpg"
      )
    }
  end
end
