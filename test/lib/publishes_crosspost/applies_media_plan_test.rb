require "test_helper"

class PublishesCrosspost::AppliesMediaPlanTest < ActiveSupport::TestCase
  PHOTO = {"type" => "image", "url" => "https://example.com/1.jpg", "alt" => "A photo"}.freeze
  CLIP = {"type" => "video", "url" => "https://example.com/clip.mp4"}.freeze
  FIVE_PHOTOS = [
    {"type" => "image", "url" => "https://example.com/1.jpg"},
    {"type" => "image", "url" => "https://example.com/2.jpg"},
    {"type" => "image", "url" => "https://example.com/3.jpg"},
    {"type" => "image", "url" => "https://example.com/4.jpg"},
    {"type" => "image", "url" => "https://example.com/5.jpg"}
  ].freeze

  def setup
    @subject = PublishesCrosspost::AppliesMediaPlan.new
    @account = accounts(:admin_x_account)
  end

  def test_attaches_media_that_fits_in_place_of_the_website_card_and_appends_the_url
    config = @subject.apply(config_with(media: [PHOTO], attach_link: true), Platforms::Bsky.new, @account)

    assert_equal [CrosspostMedia.new(type: "image", url: "https://example.com/1.jpg", alt: "A photo")], config.media
    assert_equal false, config.attach_link
    assert_equal true, config.append_url
  end

  def test_attaches_media_that_fits_without_forcing_a_url_when_no_card_was_wanted
    config = @subject.apply(config_with(media: [PHOTO, CLIP.merge("type" => "image")]), Platforms::X.new, @account)

    assert_equal 2, config.media.size
    assert_equal false, config.append_url
  end

  def test_link_fallback_drops_all_media_and_keeps_the_website_card
    config = @subject.apply(config_with(media: FIVE_PHOTOS, attach_link: true), Platforms::Bsky.new, @account)

    assert_empty config.media
    assert_equal true, config.attach_link
    assert_equal false, config.append_url
  end

  def test_link_fallback_appends_the_url_when_there_is_no_website_card
    config = @subject.apply(config_with(media: FIVE_PHOTOS), Platforms::X.new, @account)

    assert_empty config.media
    assert_equal true, config.append_url
  end

  def test_link_fallback_does_not_append_a_url_the_content_already_has
    config = @subject.apply(config_with(media: FIVE_PHOTOS, format_string: "{{title}} {{url}}"), Platforms::X.new, @account)

    assert_empty config.media
    assert_equal false, config.append_url
  end

  def test_unrecognized_fallbacks_behave_like_link
    config = @subject.apply(config_with(media: FIVE_PHOTOS, media_fallback: "lol"), Platforms::X.new, @account)

    assert_empty config.media
    assert_equal true, config.append_url
  end

  def test_best_effort_attaches_what_fits_and_links_back_to_the_rest
    config = @subject.apply(config_with(media: FIVE_PHOTOS, media_fallback: "best_effort"), Platforms::X.new, @account)

    assert_equal ["https://example.com/1.jpg", "https://example.com/2.jpg", "https://example.com/3.jpg", "https://example.com/4.jpg"], config.media.map(&:url)
    assert_equal true, config.append_url
  end

  def test_best_effort_keeps_the_first_items_kind_when_kinds_cant_mix
    config = @subject.apply(config_with(media: [CLIP, PHOTO, CLIP.merge("url" => "https://example.com/2.mp4")], media_fallback: "best_effort"), Platforms::Bsky.new, @account)

    assert_equal ["https://example.com/clip.mp4"], config.media.map(&:url)
  end

  def test_mixes_photos_and_videos_where_the_platform_allows
    config = @subject.apply(config_with(media: [CLIP, PHOTO]), Platforms::Threads.new, @account)

    assert_equal %w[video image], config.media.map(&:type)
    assert_equal false, config.append_url
  end

  def test_fail_fallback_refuses_to_publish
    error = assert_raises(PublishesCrosspost::UnretriableError) {
      @subject.apply(config_with(media: FIVE_PHOTOS, media_fallback: "fail"), Platforms::X.new, @account)
    }

    assert_equal "Can only attach 4 of this post's 5 media items, and media_fallback is \"fail\"", error.message
  end

  def test_rejected_media_counts_as_unsupported
    config = @subject.apply(config_with(media: [PHOTO, CLIP.merge("type" => "image")], media_fallback: "best_effort"), Platforms::X.new, @account, rejected_urls: ["https://example.com/1.jpg"])

    assert_equal ["https://example.com/clip.mp4"], config.media.map(&:url)
    assert_equal true, config.append_url
  end

  def test_ignores_media_for_platforms_that_do_not_attach_it
    config = @subject.apply(config_with(media: [PHOTO], attach_link: true), Platforms::Facebook.new, @account)

    assert_empty config.media
    assert_equal true, config.attach_link
    assert_equal false, config.append_url
  end

  private

  def config_with(**overrides)
    CrosspostConfig.new(
      url: "https://example.com/post",
      title: "A post",
      format_string: "{{title}}",
      append_url: false,
      attach_link: false,
      media_fallback: "link",
      media: [],
      **overrides
    )
  end
end
