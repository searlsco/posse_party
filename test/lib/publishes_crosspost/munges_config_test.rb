require "test_helper"

class PublishesCrosspost::MungesConfigTest < ActiveSupport::TestCase
  def setup
    @subject = PublishesCrosspost::MungesConfig.new
    @crosspost = crossposts(:admin_bsky_crosspost)
    @platform_defaults = {
      truncate: true,
      truncation_marker: "...",
      append_url_label_supported: true
    }
  end

  test "merges platform defaults with account and post settings" do
    # Set account-level settings
    @crosspost.account.update!(
      format_string: "Check this out: {content}",
      append_url: true,
      append_url_spacer: " - "
    )

    # Set post-level settings
    @crosspost.post.update!(
      url: "https://example.com/post",
      title: "My Post",
      content: "This is my content"
    )

    config = @subject.munge(@crosspost, @platform_defaults)

    # Platform defaults should be present
    assert_equal true, config.truncate
    assert_equal "...", config.truncation_marker
    assert_equal true, config.append_url_label_supported

    # Account settings should override platform defaults
    assert_equal "Check this out: {content}", config.format_string
    assert_equal true, config.append_url
    assert_equal " - ", config.append_url_spacer

    # Post settings should be included
    assert_equal "https://example.com/post", config.url
    assert_equal "My Post", config.title
    assert_equal "This is my content", config.content
  end

  test "post settings override account settings" do
    @crosspost.account.update!(truncate: true, append_url: false)
    @crosspost.post.update!(truncate: false, append_url: true)

    config = @subject.munge(@crosspost, @platform_defaults)

    assert_equal false, config.truncate
    assert_equal true, config.append_url
  end

  test "platform overrides take highest precedence" do
    @crosspost.account.update!(truncate: true)
    @crosspost.post.update!(
      truncate: false,
      platform_overrides: {
        "bsky" => {"truncate" => true, "format_string" => "BSKY: {content}"}
      }
    )

    config = @subject.munge(@crosspost, @platform_defaults)

    assert_equal true, config.truncate
    assert_equal "BSKY: {content}", config.format_string
  end

  test "handles nil values and missing overrides gracefully" do
    # No platform overrides for this platform
    @crosspost.post.update!(
      platform_overrides: {"twitter" => {"truncate" => false}}
    )

    config = @subject.munge(@crosspost, @platform_defaults)

    assert_not_nil config
    assert_equal true, config.truncate # Falls back to platform default
  end

  test "compact removes nil values from merge" do
    @crosspost.account.update!(append_url: nil, format_string: "test")

    config = @subject.munge(@crosspost, {append_url: true})

    assert_equal true, config.append_url # Platform default not overridden by nil
    assert_equal "test", config.format_string
  end
end
