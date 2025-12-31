require "test_helper"

class InstagramStoryImagesControllerTest < ActionDispatch::IntegrationTest
  def test_serves_instagram_story_image_bytes_when_key_is_valid
    crosspost = Crosspost.create!(
      post: New.create(Post),
      account: New.create(Account),
      status: "wip"
    )
    TemporaryAsset.create!(
      crosspost: crosspost,
      key: "story-image-key",
      bytes: "jpeg-bytes",
      content_type: "image/jpeg"
    )

    get instagram_story_image_path(key: "story-image-key")

    assert_response :ok
    assert_equal "image/jpeg", response.media_type
    assert_equal "jpeg-bytes", response.body
  end

  def test_responds_not_found_when_key_is_invalid
    crosspost = Crosspost.create!(
      post: New.create(Post),
      account: New.create(Account),
      status: "wip"
    )
    TemporaryAsset.create!(
      crosspost: crosspost,
      key: "story-image-key",
      bytes: "jpeg-bytes",
      content_type: "image/jpeg"
    )

    get instagram_story_image_path(key: "nope")

    assert_response :not_found
  end
end
