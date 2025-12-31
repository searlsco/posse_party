require "test_helper"
require "digest"
require "vips"

class InstagramTest < ActiveJob::TestCase
  def setup
    @user = New.create(User)
    @user.accounts.find_or_create_by!(platform_tag: "instagram", label: "@testman", credentials: vcr_secrets({
      "app_id" => nil, # ENV["INSTAGRAM_APP_ID"],
      "app_secret" => nil, # ENV["INSTAGRAM_APP_SECRET"],
      "user_id" => nil, # ENV["INSTAGRAM_USER_ID"],
      "access_token" => nil # ENV["INSTAGRAM_ACCESS_TOKEN"]
    }))
  end

  def test_instagram_syndication
    feed = fake_feed_from(@user, "2025-06-18-justin.searls.co.atom.xml")
    FetchesFeed.new.fetch!(feed, cache: false)
    crosspost = Post.find_by(remote_id: "https://justin.searls.co/shots/2025-06-15-14h42m44s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("instagram_shot") do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "17856798243479380", crosspost.remote_id
    assert_equal "https://www.instagram.com/p/DPzPlMyj9W8/", crosspost.url
    assert_equal <<~MSG.strip, crosspost.content
      Nearly all Japan's overtourism woes could be solved overnight if the nation simply outlawed roller bags.

      See the full post at:
      https://justin.searls.co/shots/2025-06-15-14h42m44s/
    MSG
    assert crosspost.published_at.present?
  end

  def test_instagram_syndication_with_a_clip
    feed = fake_feed_from(@user, "2025-03-12-justin.searls.co.atom.xml")
    FetchesFeed.new.fetch!(feed, cache: false)
    crosspost = Post.find_by(remote_id: "https://justin.searls.co/clips/v31-what-is-refactoring/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("instagram_clip") do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "18068450030017032", crosspost.remote_id
    assert_equal "https://www.instagram.com/reel/DPzVvaBDZvQ/", crosspost.url
    assert_equal <<~MSG.strip, crosspost.content
      New clip! What is Refactoring?

      See the full post at:
      https://justin.searls.co/clips/v31-what-is-refactoring/
    MSG
    assert crosspost.published_at.present?
  end

  def test_instagram_story_image
    feed = fake_feed_from(@user, "2025-10-12-justin.searls.co-hand-edited.atom.xml")
    FetchesFeed.new.fetch!(feed, cache: false)
    crosspost = Post.find_by(remote_id: "https://justin.searls.co/shots/2025-01-14-12h49m31s/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("instagram_story_image") do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "18068657540343979", crosspost.remote_id
    assert_nil crosspost.url
    assert crosspost.published_at.present?
  end

  def test_instagram_story_webp_photo_is_letterboxed_before_instagram_fetches_it
    webp_url = "https://posseparty.com/test-assets/3-by-4.webp"
    post_url = "https://example.com/posts/3-by-4"
    stub_request(:get, feed_url)
      .to_return(body: <<~XML, status: 200)
        <?xml version="1.0" encoding="utf-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:posse="https://posseparty.com/2024/Feed">
          <title>Test Feed</title>
          <id>#{feed_url}</id>
          <updated>2025-12-19T00:00:00Z</updated>
          <entry>
            <title>3x4 Photo</title>
            <id>#{post_url}</id>
            <published>2025-12-19T00:00:00Z</published>
            <updated>2025-12-19T00:00:00Z</updated>
            <link rel="alternate" href="#{post_url}"/>
            <posse:post><![CDATA[{"syndicate":true,"channel":"story","media":[{"type":"image","url":"#{webp_url}"}]}]]></posse:post>
          </entry>
        </feed>
      XML
    stub_request(:get, webp_url)
      .to_return(
        status: 200,
        headers: {"Content-Type" => "image/webp"},
        body: File.binread(file_fixture("3_by_4_photo.webp"))
      )
    feed = @user.feeds.create!(url: feed_url, label: "justin.searls.co - test")
    FetchesFeed.new.fetch!(feed, cache: false)
    post = Post.find_by!(remote_id: post_url)
    crosspost = Crosspost.includes(:account).find_by!(post_id: post.id)
    crosspost.update!(status: "wip")
    expected_key = Digest::SHA256.hexdigest([post.remote_id, "SOME_USER_ID", webp_url].join("|"))
    expected_query = {
      access_token: "SOME_ACCESS_TOKEN",
      media_type: "STORIES",
      image_url: "http://posseparty.com/instagram/story_images/#{expected_key}"
    }
    calls_instagram_api = Mocktail.of_next(Platforms::Instagram::CallsInstagramApi)
    stubs { calls_instagram_api.call(method: :post, path: "SOME_USER_ID/media", query: expected_query) }.with {
      Platforms::Instagram::CallsInstagramApi::Result.new(
        success?: false,
        data: {error: {code: 352, error_subcode: "2207008", type: "OAuthException", fbtrace_id: "fbtrace"}},
        message: "Waiting for Instagram container to exist"
      )
    }
    result = nil

    assert_enqueued_with(job: FinishCrosspostJob, args: [crosspost.id]) do
      result = PublishesCrosspost.new.publish(crosspost.id)
    end

    crosspost.reload
    assert result.success?
    assert result.needs_to_finish?
    assert_equal "wip", crosspost.status
    assert_equal "story", post.channel
    assert_equal [{"type" => "image", "url" => webp_url}], post.media
    temporary_asset = crosspost.temporary_asset
    assert_equal expected_key, temporary_asset.key
    assert_equal "\xFF\xD8\xFF".b, temporary_asset.bytes.byteslice(0, 3)
    image = Vips::Image.new_from_buffer(temporary_asset.bytes, "")
    assert_equal 2000, image.width
    assert_equal 3556, image.height
    assert_equal [0.0, 0.0, 0.0], image.getpoint(1000, 0)
    assert_equal [0.0, 0.0, 0.0], image.getpoint(1000, 3555)

    crop_height = (image.width * 4.0 / 3).round
    crop_top = ((image.height - crop_height) / 2.0).round
    cropped_image = image.crop(0, crop_top, image.width, crop_height)

    fixture_image = Vips::Image.new_from_file(file_fixture("3_by_4_photo.webp").to_s)
      .autorot
      .colourspace("srgb")
    fixture_image = fixture_image.extract_band(0, n: 3) if fixture_image.bands > 3

    resized_fixture_image = fixture_image.resize(image.width.fdiv(fixture_image.width))
    cropped_fixture_image = resized_fixture_image.crop(0, ((resized_fixture_image.height - crop_height) / 2.0).round, image.width, crop_height)

    assert_equal image.width, cropped_image.width
    assert_equal crop_height, cropped_image.height
    assert_equal image.width, cropped_fixture_image.width
    assert_equal crop_height, cropped_fixture_image.height
    assert_in_delta crop_top, image.height - (crop_top + crop_height), 1
    assert_operator (cropped_image - cropped_fixture_image).abs.avg, :<, 5.0
    verify { calls_instagram_api.call(method: :post, path: "SOME_USER_ID/media", query: expected_query) }
  end

  def test_instagram_story_video
    feed = fake_feed_from(@user, "2025-10-12-justin.searls.co-hand-edited.atom.xml")
    FetchesFeed.new.fetch!(feed, cache: false)
    crosspost = Post.find_by(remote_id: "https://justin.searls.co/clips/v31-what-is-refactoring/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("instagram_story_video") do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "18059239898533002", crosspost.remote_id
    assert_nil crosspost.url
    assert crosspost.published_at.present?
  end

  def test_invalid_story_video
    feed = fake_feed_from(@user, "2025-10-14-beckygram-stories-invalid-videos.atom.xml")
    FetchesFeed.new.fetch!(feed, cache: false)
    crosspost = Post.find_by(remote_id: "1760362905").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("instagram_story_video_invalid") do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_equal "failed", crosspost.reload.status
    assert_equal 1, crosspost.attempts # It's an unretriable, unrecoverable error
    assert_equal 1, crosspost.failures.size
    # Content now sanitized to plaintext; media tags are removed upstream.
    assert_equal <<~MSG.strip, crosspost.content
      See the full post at:
      https://example.com/not_applicable
    MSG
    assert_nil crosspost.remote_id
    assert_nil crosspost.url
    assert_nil crosspost.published_at
    assert crosspost.last_attempted_at.present?
    assert_equal <<~MSG.strip, crosspost.failures.first["message"]
      Instagram API error for story: Unsupported format — The video format is not supported: Unsupported format: The video format is not supported: STORY
      Details: code=352, subcode=2207026.
      Learn more: Specs https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/media#image-specifications | Errors https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/error-codes
    MSG
    assert_equal <<~MSG.strip, crosspost.failures.first["cause"].strip
      Error calling Instagram API.

      Response:
      {
        "error": {
          "message": "The video file you selected is in a format that we don't support.",
          "type": "OAuthException",
          "code": 352,
          "error_subcode": 2207026,
          "is_transient": false,
          "error_user_title": "Unsupported format",
          "error_user_msg": "The video format is not supported: Unsupported format: The video format is not supported: STORY",
          "fbtrace_id": "A-2Z0meUgbiLdggnvDJiG_j"
        }
      }

      Request:
      URL: https://graph.instagram.com/v24.0/SOME_USER_ID/media_publish
      Method: POST
      Query:
      {
        "access_token": "SOME_ACCESS_TOKEN",
        "creation_id": "17874554361429190"
      }
       (code=352, subcode=2207026, type=OAuthException, fbtrace_id=A-2Z0meUgbiLdggnvDJiG_j, request=POST SOME_USER_ID/media_publish)
    MSG
  end

  def test_instagram_syndication_with_carousel_of_video
    feed = fake_feed_from(@user, "2025-10-12-justin.searls.co-hand-edited.atom.xml")
    FetchesFeed.new.fetch!(feed, cache: false)

    crosspost = Post.find_by(remote_id: "https://justin.searls.co/shots/fake-lol/").crossposts.first
    crosspost.update!(status: "wip")

    perfect_vcr_match("instagram_carousel") do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal 1, crosspost.attempts
    assert_equal "17896425363324552", crosspost.remote_id
    assert_equal "https://www.instagram.com/p/DP2Hp0RDxWo/", crosspost.url
    assert_equal <<~MSG.strip, crosspost.content
      pretend i'm a big carousel

      See the full post at:
      https://justin.searls.co/shots/fake-lol/
    MSG
    assert crosspost.published_at.present?
  end
end
