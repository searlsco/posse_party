module Platforms
  class Base
    EMPTY_ARRAY = [].freeze
    EMPTY_HASH = {}.freeze
    SUPPORTED_CHANNELS = %w[feed].freeze

    def default_crosspost_options
      fetch_constant(:DEFAULT_CROSSPOST_OPTIONS, Platforms::DEFAULT_CROSSPOST_OPTIONS)
    end

    # Platforms that attach a post's media declare MEDIA_CONSTRAINTS. Those that don't (or that handle media on their own terms) return nil.
    def media_constraints(_account)
      fetch_constant(:MEDIA_CONSTRAINTS, nil)
    end

    def post_constraints
      fetch_constant(:POST_CONSTRAINTS, Constants::DEFAULT_POST_CONSTRAINTS)
    end

    def publish!(crosspost, crosspost_config, crosspost_content)
      raise NotImplementedError, "#{self.class.name} must implement #publish!"
    end

    def finishable?
      false
    end

    def finish!(crosspost)
      raise NotImplementedError, "#{self.class.name} must implement #finish!"
    end

    def renewable?
      fetch_constant(:RENEWABLE, false)
    end

    def renewal_url_supported?
      fetch_constant(:RENEWAL_URL_SUPPORTED, false)
    end

    def renew!(_account)
      raise NotImplementedError, "#{self.class.name} must implement #renew!"
    end

    def renewal_url(_account, _state)
      raise NotImplementedError, "#{self.class.name} must implement #renewal_url"
    end

    def required_credentials
      fetch_constant(:REQUIRED_CREDENTIALS, EMPTY_ARRAY)
    end

    def credential_labels
      fetch_constant(:CREDENTIAL_LABELS, EMPTY_HASH)
    end

    def irrelevant_config_options
      fetch_constant(:IRRELEVANT_CONFIG_OPTIONS, EMPTY_ARRAY)
    end

    def embed_support?
      fetch_constant(:EMBED_SUPPORTED, false)
    end

    def embed_html(_crosspost)
      nil
    end

    def manual_compose_url(_crosspost_content)
      nil
    end

    def supports_channel?(channel)
      fetch_constant(:SUPPORTED_CHANNELS, %w[feed]).include?(channel.to_s)
    end

    def setup_docs_available?
      false
    end

    private

    def fetch_constant(name, fallback)
      if self.class.const_defined?(name, false)
        self.class.const_get(name)
      else
        fallback
      end
    end
  end
end
