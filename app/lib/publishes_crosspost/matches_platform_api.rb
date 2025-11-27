class PublishesCrosspost
  class MatchesPlatformApi
    PLATFORMS = [
      Platforms::Bsky,
      Platforms::X,
      Platforms::Mastodon,
      Platforms::Threads,
      Platforms::Instagram,
      Platforms::Facebook,
      Platforms::Linkedin,
      Platforms::Youtube
    ].freeze

    def initialize
      @parses_env_boolean = ParsesEnvBoolean.new
    end

    def match(account)
      return Platforms::Null.new(account) if @parses_env_boolean.parse("USE_NULL_ADAPTERS", default: false)
      return Platforms::Test.new(account) if account.platform_tag == Platforms::Test::TAG && !Rails.env.production?
      return Platforms::TestFailure.new if account.platform_tag == Platforms::TestFailure::TAG && !Rails.env.production?
      return Platforms::TestSkipped.new(account) if account.platform_tag == Platforms::TestSkipped::TAG && !Rails.env.production?

      if (platform_class = PLATFORMS.find { |klass| account.platform_tag == klass::TAG })
        platform_class.new
      else
        raise "Unsupported platform: #{account.platform_tag.inspect}"
      end
    end
  end
end
