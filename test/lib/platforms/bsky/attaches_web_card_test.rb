require "test_helper"

class Platforms::Bsky::AttachesWebCardTest < ActiveSupport::TestCase
  def test_uses_summary_when_og_description_is_missing
    subject = Platforms::Bsky::AttachesWebCard.new
    crosspost_config = CrosspostConfig.new(
      url: "https://example.com/posts/123",
      title: "A Consistent Title",
      summary: "A consistent description",
      og_title: nil,
      og_description: nil,
      og_image: nil
    )

    result = subject.attach!(crosspost_config, nil)

    assert_equal "app.bsky.embed.external", result["$type"]
    assert_equal "https://example.com/posts/123", result["external"]["uri"]
    assert_equal "A Consistent Title", result["external"]["title"]
    assert_equal "A consistent description", result["external"]["description"]
  end
end
