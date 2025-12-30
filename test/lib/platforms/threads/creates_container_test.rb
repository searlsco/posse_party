require "test_helper"
require "mocktail"

class Platforms::Threads::CreatesContainerTest < ActiveSupport::TestCase
  def test_uses_link_attachment_without_description_metadata
    api = Mocktail.of_next(Platforms::Threads::CallsThreadsApi)
    subject = Platforms::Threads::CreatesContainer.new
    crosspost_config = CrosspostConfig.new(
      url: "https://example.com/posts/123",
      attach_link: true,
      og_description: "A consistent description",
      summary: "A consistent summary"
    )

    expected_query = {
      text: "Post body",
      media_type: "TEXT",
      link_attachment: "https://example.com/posts/123",
      access_token: "token"
    }

    stubs {
      api.call(method: :post, path: "me/threads", query: expected_query)
    }.with {
      Platforms::Threads::CallsThreadsApi::Result.new(success?: true, data: {id: "THREAD123"})
    }

    result = subject.create("Post body", crosspost_config, access_token: "token")

    assert result.success?
    verify {
      api.call(method: :post, path: "me/threads", query: expected_query)
    }
  end
end
