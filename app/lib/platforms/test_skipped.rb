module Platforms
  class TestSkipped < Base
    TAG = "test_skipped"
    LABEL = "Test Skipped"

    POST_CONSTRAINTS = Constants::DEFAULT_POST_CONSTRAINTS.freeze

    DEFAULT_CROSSPOST_OPTIONS = Platforms::Test::DEFAULT_CROSSPOST_OPTIONS.merge(
      syndicate: false
    ).freeze

    def initialize(account)
      @account = account
    end

    def publish!(_crosspost, _crosspost_config, _crosspost_content)
      PublishesCrosspost::Result.new(success?: true)
    end
  end
end
