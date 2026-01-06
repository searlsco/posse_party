require "test_helper"
require "mocktail"

class Platforms::Linkedin::PublishesPostTest < ActiveSupport::TestCase
  def test_uses_title_and_summary_for_link_card_metadata
    api = Mocktail.of_next(Platforms::Linkedin::CallsLinkedinApi)
    subject = Platforms::Linkedin::PublishesPost.new

    crosspost_config = CrosspostConfig.new(
      url: "https://example.com/posts/123",
      title: "A Consistent Title",
      summary: "A consistent description",
      og_title: nil,
      og_description: nil
    )

    expected_body = subject.send(
      :build_post_data,
      "Post body",
      crosspost_config,
      person_urn: "urn:li:person:abc123",
      image_urn: nil,
      url: crosspost_config.url
    )
    assert_equal "A Consistent Title", expected_body.dig(:content, :article, :title)
    assert_equal "A consistent description", expected_body.dig(:content, :article, :description)

    stubs {
      api.call(
        method: :post,
        path: "rest/posts",
        body: expected_body,
        access_token: "token"
      )
    }.with {
      Platforms::Linkedin::CallsLinkedinApi::Result.new(
        success?: true,
        headers: {"x-restli-id" => "urn:li:share:123"}
      )
    }

    result = subject.publish(
      "Post body",
      crosspost_config,
      access_token: "token",
      person_urn: "urn:li:person:abc123",
      image_urn: nil,
      url: crosspost_config.url
    )

    assert result.success?
    verify {
      api.call(
        method: :post,
        path: "rest/posts",
        body: expected_body,
        access_token: "token"
      )
    }
  end

  def test_uses_truncated_content_when_no_title_is_available
    api = Mocktail.of_next(Platforms::Linkedin::CallsLinkedinApi)
    subject = Platforms::Linkedin::PublishesPost.new
    content = "This is a long LinkedIn post body that should be truncated for the title."
    title_limit = Platforms::Linkedin::PublishesPost::TITLE_MAX_LENGTH
    assert content.length > title_limit

    crosspost_config = CrosspostConfig.new(
      url: "https://example.com/posts/456",
      title: nil,
      summary: "A consistent description",
      og_title: nil,
      og_description: nil
    )

    expected_body = subject.send(
      :build_post_data,
      content,
      crosspost_config,
      person_urn: "urn:li:person:def456",
      image_urn: nil,
      url: crosspost_config.url
    )
    assert_equal content.truncate(title_limit), expected_body.dig(:content, :article, :title)
    assert_equal "A consistent description", expected_body.dig(:content, :article, :description)

    stubs {
      api.call(
        method: :post,
        path: "rest/posts",
        body: expected_body,
        access_token: "token"
      )
    }.with {
      Platforms::Linkedin::CallsLinkedinApi::Result.new(
        success?: true,
        headers: {"x-restli-id" => "urn:li:share:456"}
      )
    }

    result = subject.publish(
      content,
      crosspost_config,
      access_token: "token",
      person_urn: "urn:li:person:def456",
      image_urn: nil,
      url: crosspost_config.url
    )

    assert result.success?
    verify {
      api.call(
        method: :post,
        path: "rest/posts",
        body: expected_body,
        access_token: "token"
      )
    }
  end

  def test_truncates_summary_when_it_exceeds_linkedin_limit
    api = Mocktail.of_next(Platforms::Linkedin::CallsLinkedinApi)
    subject = Platforms::Linkedin::PublishesPost.new
    summary_limit = Platforms::Linkedin::PublishesPost::DESCRIPTION_MAX_LENGTH
    long_summary = "a" * (summary_limit + 5)

    crosspost_config = CrosspostConfig.new(
      url: "https://example.com/posts/789",
      title: "A Summary Truncation Title",
      summary: long_summary,
      og_title: nil,
      og_description: nil
    )

    expected_body = subject.send(
      :build_post_data,
      "Post body",
      crosspost_config,
      person_urn: "urn:li:person:ghi789",
      image_urn: nil,
      url: crosspost_config.url
    )
    assert_equal long_summary.truncate(4084), expected_body.dig(:content, :article, :description)

    stubs {
      api.call(
        method: :post,
        path: "rest/posts",
        body: expected_body,
        access_token: "token"
      )
    }.with {
      Platforms::Linkedin::CallsLinkedinApi::Result.new(
        success?: true,
        headers: {"x-restli-id" => "urn:li:share:789"}
      )
    }

    result = subject.publish(
      "Post body",
      crosspost_config,
      access_token: "token",
      person_urn: "urn:li:person:ghi789",
      image_urn: nil,
      url: crosspost_config.url
    )

    assert result.success?
    verify {
      api.call(
        method: :post,
        path: "rest/posts",
        body: expected_body,
        access_token: "token"
      )
    }
  end
end
