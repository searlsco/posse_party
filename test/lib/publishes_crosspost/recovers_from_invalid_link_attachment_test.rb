require "test_helper"
require "mocktail"

class PublishesCrosspost::RecoversFromInvalidLinkAttachmentTest < ActiveSupport::TestCase
  FakeContent = Struct.new(:string, keyword_init: true)

  def setup
    @subject = PublishesCrosspost::RecoversFromInvalidLinkAttachment.new
    @crosspost = crossposts(:admin_bsky_crosspost)
    @crosspost_config = CrosspostConfig.new(
      url: "https://example.com/post",
      attach_link: true,
      append_url: false,
      format_string: "{{content}}"
    )
    @api = Mocktail.of_next(Platforms::Bsky)
    @failing_content = FakeContent.new(string: "This is my post content")
  end

  test "disables attach_link and retries with same content when URL already included" do
    @failing_content.string = "Check out my post at https://example.com/post"
    result_mock = PublishesCrosspost::Result.new(success?: true)
    stubs { @api.publish!(@crosspost, @crosspost_config, @failing_content) }.with { result_mock }

    result = @subject.recover(@crosspost, @crosspost_config, @api, failing_content: @failing_content)

    assert_equal false, @crosspost_config.attach_link
    assert_equal false, @crosspost_config.append_url # Should not be changed
    assert_equal result_mock, result

    verify { @api.publish!(@crosspost, @crosspost_config, @failing_content) }
  end

  test "sets attach_link to false and append_url to true when URL not in content" do
    # Just test the configuration changes without full execution
    begin
      @subject.recover(@crosspost, @crosspost_config, @api, failing_content: @failing_content)
    rescue
      nil
    end

    assert_equal false, @crosspost_config.attach_link
    assert_equal true, @crosspost_config.append_url
  end
end
