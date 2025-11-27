require_relative "mail_delivery/base_http_delivery"
require_relative "mail_delivery/resend_delivery"
require_relative "mail_delivery/mailgun_delivery"
require_relative "mail_delivery/postmark_delivery"
require_relative "mail_delivery/sendgrid_delivery"
require_relative "mail_delivery/brevo_delivery"
require_relative "mail_delivery/mailjet_delivery"

class ConfiguresMailer
  PROVIDERS = {
    amazon_ses: {delivery_method: :ses_api, required_env: %w[AWS_SES_REGION AWS_SES_ACCESS_KEY_ID AWS_SES_SECRET_ACCESS_KEY]},
    resend: {delivery_method: :resend_api, required_env: %w[RESEND_API_KEY], adapter: MailDelivery::ResendDelivery},
    mailgun: {delivery_method: :mailgun_api, required_env: %w[MAILGUN_API_KEY MAILGUN_DOMAIN], adapter: MailDelivery::MailgunDelivery},
    postmark: {delivery_method: :postmark_api, required_env: %w[POSTMARK_API_TOKEN], adapter: MailDelivery::PostmarkDelivery},
    sendgrid: {delivery_method: :sendgrid_api, required_env: %w[SENDGRID_API_KEY], adapter: MailDelivery::SendgridDelivery},
    brevo: {delivery_method: :brevo_api, required_env: %w[BREVO_API_KEY], adapter: MailDelivery::BrevoDelivery},
    mailjet: {delivery_method: :mailjet_api, required_env: %w[MAILJET_API_KEY MAILJET_API_SECRET], adapter: MailDelivery::MailjetDelivery},
    smtp: {delivery_method: :smtp, required_env: %w[SMTP_HOST SMTP_USERNAME SMTP_PASSWORD]}
  }.freeze

  PREFERRED_FALLBACK_ORDER = %i[amazon_ses resend mailgun postmark sendgrid brevo mailjet smtp].freeze

  def initialize
    @parses_env_boolean = ParsesEnvBoolean.new
  end

  def configure!
    provider_key = selected_provider_key
    provider = PROVIDERS.fetch(provider_key) { raise ArgumentError, "Unknown MAIL_PROVIDER '#{provider_key}'" }

    register_adapter(provider)
    apply_provider_settings(provider)

    provider[:delivery_method]
  end

  private

  def selected_provider_key
    explicit = ENV["MAIL_PROVIDER"].to_s.strip
    return resolve_provider_from_env if explicit.blank?

    explicit.downcase.to_sym
  end

  def resolve_provider_from_env
    PREFERRED_FALLBACK_ORDER.find do |provider|
      required = PROVIDERS[provider][:required_env]
      required.all? { |key| ENV[key].present? }
    end || :smtp
  end

  def register_adapter(provider)
    adapter_class = provider[:adapter]
    return unless adapter_class

    delivery_method = provider[:delivery_method]
    return if ActionMailer::Base.delivery_methods.key?(delivery_method)

    ActionMailer::Base.add_delivery_method(delivery_method, adapter_class)
  end

  def apply_provider_settings(provider)
    case provider[:delivery_method]
    when :ses_api
      Aws.config.update(
        access_key_id: ENV["AWS_SES_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SES_SECRET_ACCESS_KEY"],
        region: ENV["AWS_SES_REGION"]
      )
    when :smtp
      ActionMailer::Base.smtp_settings = smtp_settings
    end
  end

  def smtp_settings
    user = ENV["SMTP_USERNAME"].presence
    pass = ENV["SMTP_PASSWORD"].presence

    {
      address: ENV["SMTP_HOST"],
      user_name: user,
      password: pass,
      port: (ENV["SMTP_PORT"].presence || 587).to_i,
      authentication: (:login if user.present?),
      enable_starttls: @parses_env_boolean.parse("SMTP_ENABLE_STARTTLS", default: true)
    }.compact
  end
end
