require "test_helper"

class PublishesCrosspost::AppliesFormatStringTest < ActiveSupport::TestCase
  def setup
    @subject = PublishesCrosspost::AppliesFormatString.new
  end

  test "replaces template variables with values from config" do
    config = {
      format_string: "{{title}}: {{content}}",
      title: "My Post",
      content: "This is the content"
    }

    result = @subject.apply(config)

    assert_equal "My Post: This is the content", result
  end

  test "handles missing template variables gracefully" do
    config = {
      format_string: "Title: {{title}} - Author: {{author}}",
      title: "My Post"
      # author is missing
    }

    result = @subject.apply(config)

    assert_equal "Title: My Post - Author:", result
  end

  test "normalizes unicode and removes extra spaces" do
    config = {
      format_string: "{{content}}",
      content: "Text  with   extra    spaces"
    }

    result = @subject.apply(config)

    assert_equal "Text with extra spaces", result
  end

  test "removes trailing spaces before newlines" do
    config = {
      format_string: "{{content}}",
      content: "Line one   \nLine two"
    }

    result = @subject.apply(config)

    assert_equal "Line one\nLine two", result
  end

  test "strips leading and trailing whitespace" do
    config = {
      format_string: "  {{content}}  \n",
      content: "My content"
    }

    result = @subject.apply(config)

    assert_equal "My content", result
  end

  test "handles complex nested template" do
    config = {
      format_string: "{{title}}\n\n{{content}}\n\n{{url}}",
      title: "Great Article",
      content: "Read this amazing post",
      url: "https://example.com"
    }

    result = @subject.apply(config)

    assert_equal "Great Article\n\nRead this amazing post\n\nhttps://example.com", result
  end
end
