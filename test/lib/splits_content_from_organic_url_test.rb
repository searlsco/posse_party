require "test_helper"

class SplitsContentFromOrganicUrlTest < ActiveSupport::TestCase
  FakeConfig = Struct.new(:attach_link, :url, keyword_init: true)

  def setup
    @subject = SplitsContentFromOrganicUrl.new
    @config = FakeConfig.new(attach_link: false, url: "https://example.com")
  end

  test "returns content and config URL when attach_link is true" do
    @config.attach_link = true
    content = "This is my post"

    result = @subject.split(@config, content)

    assert_equal ["This is my post", "https://example.com"], result
  end

  test "extracts organic URL from end of content" do
    content = "Check out this cool post https://organic-url.com"

    result = @subject.split(@config, content)

    assert_equal ["Check out this cool post", "https://organic-url.com"], result
  end

  test "handles URL with trailing whitespace" do
    content = "My post content https://example.org  \n"

    result = @subject.split(@config, content)

    assert_equal ["My post content", "https://example.org"], result
  end

  # real bug: https://posseparty.com/crossposts/2507
  test "handles asterisks" do
    text = "Feel like Becky's podcast is starting to hit its stride. Really enjoyed today's episode.*\n\n*Conflict of interest: I am married to Becky and therefore predisposed to judging it more harshly"
    url = "https://gram.betterwithbecky.com/podcasts/9"
    content = "#{text} #{url}"

    result = @subject.split(@config, content)

    assert_equal [text, url], result
  end

  test "returns content and nil when no URL present" do
    content = "Just some text without any URL"

    result = @subject.split(@config, content)

    assert_equal ["Just some text without any URL", nil], result
  end

  test "returns content and nil when URL is in middle of content" do
    content = "Check https://example.com out in the middle"

    result = @subject.split(@config, content)

    assert_equal ["Check https://example.com out in the middle", nil], result
  end

  test "handles empty config URL" do
    @config.url = ""
    @config.attach_link = true
    content = "My content"

    result = @subject.split(@config, content)

    assert_equal ["My content", nil], result
  end
end
