require "test_helper"

class TranslatesInstagramPostTest < ActiveSupport::TestCase
  FakePost = Struct.new(:url, :media, keyword_init: true)
  FakeCrosspost = Struct.new(:post, :content, keyword_init: true)

  def test_translates_poster_url_to_cover_url
    translator = Platforms::Instagram::TranslatesInstagramPost.new

    post = FakePost.new(
      url: "https://example.com/post",
      media: [
        {
          "type" => "video",
          "url" => "https://example.com/video.mp4",
          "poster_url" => "https://example.com/poster.jpg"
        }
      ]
    )

    crosspost = FakeCrosspost.new(
      post: post,
      content: "Some caption"
    )

    instagram_post = translator.from_crosspost(crosspost)

    assert_equal "REELS", instagram_post.media_type
    assert_equal "https://example.com/post", instagram_post.url
    assert_equal 1, instagram_post.medias.size
    assert_equal "VIDEO", instagram_post.medias.first.media_type
    assert_equal "https://example.com/video.mp4", instagram_post.medias.first.url
    assert_equal "https://example.com/poster.jpg", instagram_post.medias.first.cover_url
  end
end
