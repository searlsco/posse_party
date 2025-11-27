module Platforms
  class Null < Base
    DEFAULT_CROSSPOST_OPTIONS = {}.freeze
    RENEWABLE = true

    def initialize(account)
      @account = account
      @publishes = []
      @renewals = []
    end

    def publish!(crosspost, crosspost_config, crosspost_content)
      @publishes << {
        account: @account,
        crosspost:,
        crosspost_config:,
        crosspost_content:
      }
      Rails.logger.info "Simulated publish to #{@account.platform_tag.capitalize} for Crosspost #{crosspost.id} and Post #{crosspost.post_id}."
      PublishesCrosspost::Result.new(success?: true)
    end

    def renew!(account)
      @renewals << {
        account:,
        renewed_at: Now.time
      }
      Rails.logger.info "Simulated renewal to #{account.platform_tag.capitalize} for account #{account.id}."
      Outcome.success
    end
  end
end
