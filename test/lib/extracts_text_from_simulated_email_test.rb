require "test_helper"

class ExtractsTextFromSimulatedEmailTest < ActiveSupport::TestCase
  class FakePart
    def initialize(text)
      @text = text
    end

    def decoded
      @text
    end
  end

  class FakePreview
    attr_reader :message
    def initialize(message)
      @message = message
    end
  end

  FakeBody = Struct.new(:decoded, keyword_init: true)
  FakeMessage = Struct.new(:text_part, :html_part, :content_type, :body, keyword_init: true)

  class FakeMailer
    def self.with(params)
      @params = params
      self
    end

    def self.notify
      message = FakeMessage.new(
        text_part: FakePart.new("Hello world https://example.com/a"),
        html_part: nil,
        content_type: "multipart/alternative",
        body: FakeBody.new(decoded: "ignored")
      )
      FakePreview.new(message)
    end
  end

  def setup
    @subject = ExtractsTextFromSimulatedEmail.new
  end

  test "extracts text and URLs from preview message" do
    result = @subject.extract(mail: FakeMailer, method: :notify, params: {a: 1})
    assert_equal "Hello world https://example.com/a", result.text
    assert_equal [{"url" => "https://example.com/a"}], result.refs
  end

  test "falls back to body when content-type is text/plain" do
    mailer = Class.new do
      def self.with(params)
        self
      end

      def self.notify
        message = ExtractsTextFromSimulatedEmailTest::FakeMessage.new(
          text_part: nil,
          html_part: nil,
          content_type: "text/plain; charset=UTF-8",
          body: ExtractsTextFromSimulatedEmailTest::FakeBody.new(decoded: "Plain https://x.test")
        )
        ExtractsTextFromSimulatedEmailTest::FakePreview.new(message)
      end
    end
    result = @subject.extract(mail: mailer, method: :notify, params: {})
    assert_equal "Plain https://x.test", result.text
    assert_equal [{"url" => "https://x.test"}], result.refs
  end
end
