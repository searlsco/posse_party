require "test_helper"

class GeneratesStoryImageUrlTest < ActiveSupport::TestCase
  def test_persists_letterboxed_story_image_bytes_and_returns_a_public_url
    post = New.create(Post, remote_id: "https://example.com/post", url: "https://example.com/post")
    crosspost = Crosspost.create!(
      post: post,
      account: New.create(Account,
        platform_tag: "instagram",
        label: "@testman",
        credentials: {
          "app_id" => "SOME_APP_ID",
          "app_secret" => "SOME_APP_SECRET",
          "user_id" => "SOME_USER_ID",
          "access_token" => "SOME_ACCESS_TOKEN"
        }),
      status: "wip"
    )
    letterboxes_image_with_vips = Mocktail.of_next(LetterboxesImageWithVips)
    stub_request(:get, "https://example.com/image.jpg")
      .to_return(status: 200, body: "source-bytes")
    stubs { letterboxes_image_with_vips.letterbox("source-bytes") }.with { "letterboxed-bytes" }

    url = Platforms::Instagram::GeneratesStoryImageUrl.new.generate(crosspost, "https://example.com/image.jpg")
    temporary_asset = crosspost.reload.temporary_asset

    assert_equal "letterboxed-bytes", temporary_asset.bytes
    assert_equal "042e237f27c66ee515915e955c89c5532fa786548db8f500dc1e7e28ab2fc075", temporary_asset.key
    assert_equal "http://posseparty.com/instagram/story_images/042e237f27c66ee515915e955c89c5532fa786548db8f500dc1e7e28ab2fc075", url
  end

  def test_reuses_persisted_story_image_bytes_without_redownloading
    post = New.create(Post, remote_id: "https://example.com/post", url: "https://example.com/post")
    crosspost = Crosspost.create!(
      post: post,
      account: New.create(Account,
        platform_tag: "instagram",
        label: "@testman",
        credentials: {
          "app_id" => "SOME_APP_ID",
          "app_secret" => "SOME_APP_SECRET",
          "user_id" => "SOME_USER_ID",
          "access_token" => "SOME_ACCESS_TOKEN"
        }),
      status: "wip",
      temporary_asset: TemporaryAsset.new(
        key: "042e237f27c66ee515915e955c89c5532fa786548db8f500dc1e7e28ab2fc075",
        bytes: "already-there",
        content_type: "image/jpeg"
      )
    )
    letterboxes_image_with_vips = Mocktail.of_next(LetterboxesImageWithVips)
    stub_request(:get, "https://example.com/image.jpg")
      .to_return(status: 200, body: "source-bytes")

    url = Platforms::Instagram::GeneratesStoryImageUrl.new.generate(crosspost, "https://example.com/image.jpg")

    verify_never_called { letterboxes_image_with_vips.letterbox("source-bytes") }
    assert_not_requested(:get, "https://example.com/image.jpg")
    assert_equal "042e237f27c66ee515915e955c89c5532fa786548db8f500dc1e7e28ab2fc075", crosspost.reload.temporary_asset.key
    assert_equal "http://posseparty.com/instagram/story_images/042e237f27c66ee515915e955c89c5532fa786548db8f500dc1e7e28ab2fc075", url
  end
end
