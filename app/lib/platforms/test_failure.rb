module Platforms
  class TestFailure < Base
    TAG = "test_failure"
    LABEL = "Test Failure"

    POST_CONSTRAINTS = Constants::DEFAULT_POST_CONSTRAINTS.merge(
      character_limit: 280,
      counter: ->(text) { text.length },
      hashtag_pattern: /#\w+/,
      url_pattern: /https?:\/\/[^\s]+/
    ).freeze

    DEFAULT_CROSSPOST_OPTIONS = Platforms::DEFAULT_CROSSPOST_OPTIONS.merge(
      format_string: "{{content}}"
    ).freeze

    def initialize
    end

    def publish!(_crosspost, _crosspost_config, _crosspost_content)
      PublishesCrosspost::Result.new(success?: false, message: "Simulated publish failure")
    end
  end
end
