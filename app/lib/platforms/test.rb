module Platforms
  class Test < Base
    TAG = "test"
    LABEL = "Test"

    POST_CONSTRAINTS = Constants::DEFAULT_POST_CONSTRAINTS.merge(
      character_limit: 280,
      counter: ->(text) { text.length },
      hashtag_pattern: /#\w+/,
      url_pattern: /https?:\/\/[^\s]+/
    ).freeze

    DEFAULT_CROSSPOST_OPTIONS = Platforms::DEFAULT_CROSSPOST_OPTIONS.merge(
      format_string: "{{content}}"
    ).freeze

    @@interactions = []

    def self.interactions
      @@interactions
    end

    def self.reset_interactions!
      @@interactions = []
    end

    def initialize(account)
      @account = account
    end

    def publish!(crosspost, crosspost_config, crosspost_content)
      crosspost.update!(status: "published")
      interaction = {
        account: @account,
        crosspost: crosspost,
        crosspost_config: crosspost_config,
        crosspost_content: crosspost_content,
        published_at: Now.time
      }
      @@interactions << interaction
      Rails.logger.info "Test publish captured for Crosspost #{crosspost.id} and Post #{crosspost.post_id}."
      PublishesCrosspost::Result.new(success?: true)
    end
  end
end
