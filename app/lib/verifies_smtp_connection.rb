class VerifiesSmtpConnection
  Result = Struct.new(:configured?, :connected?, :error, keyword_init: true)

  def verify
    if ses_delivery?
      verify_ses
    elsif smtp_configured?
      attempt_connection
    elsif http_delivery?
      Result.new(configured?: http_configured?, connected?: http_configured?, error: nil)
    else
      Result.new(configured?: false, connected?: false, error: nil)
    end
  rescue => exception
    Result.new(configured?: delivery_configured?, connected?: false, error: "#{exception.class}: #{exception.message}")
  end

  def ses_delivery?
    ActionMailer::Base.delivery_method == :ses_api
  end

  def verify_ses
    client = Aws::SESV2::Client.new(
      region: ENV["AWS_SES_REGION"],
      access_key_id: ENV["AWS_SES_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SES_SECRET_ACCESS_KEY"]
    )

    client.get_account

    Result.new(configured?: true, connected?: true, error: nil)
  rescue => e
    Result.new(configured?: true, connected?: false, error: e.message)
  end

  def delivery_configured?
    ses_delivery? || smtp_delivery? || http_delivery?
  end

  private

  def attempt_connection
    settings = ActionMailer::Base.smtp_settings || {}
    address = settings[:address].to_s.strip
    port = (settings[:port] || 587).to_i
    enable_starttls = smtp_starttls_enabled?(settings, port)

    require "net/smtp"
    smtp = Net::SMTP.new(address, port)
    smtp.open_timeout = 5
    smtp.read_timeout = 5
    configure_tls(smtp, port, enable_starttls)
    smtp.start(Socket.gethostname) { |_session| }

    Result.new(configured?: true, connected?: true, error: nil)
  end

  def configure_tls(smtp, port, enable_starttls)
    if port == 465
      smtp.enable_tls
    elsif enable_starttls
      smtp.enable_starttls_auto
    end
  end

  def smtp_configured?
    return false unless smtp_delivery?

    settings = ActionMailer::Base.smtp_settings || {}

    address = settings[:address].presence
    return false if address.blank?

    user = settings[:user_name].to_s
    pass = settings[:password].to_s
    return false if (user.present? && pass.blank?) || (pass.present? && user.blank?)

    true
  end

  def http_delivery?
    [:resend_api, :mailgun_api, :postmark_api, :sendgrid_api, :brevo_api, :mailjet_api].include?(ActionMailer::Base.delivery_method)
  end

  def http_configured?
    case ActionMailer::Base.delivery_method
    when :resend_api
      ENV["RESEND_API_KEY"].present?
    when :mailgun_api
      ENV["MAILGUN_API_KEY"].present? && ENV["MAILGUN_DOMAIN"].present?
    when :postmark_api
      ENV["POSTMARK_API_TOKEN"].present?
    when :sendgrid_api
      ENV["SENDGRID_API_KEY"].present?
    when :brevo_api
      ENV["BREVO_API_KEY"].present?
    when :mailjet_api
      ENV["MAILJET_API_KEY"].present? && ENV["MAILJET_API_SECRET"].present?
    else
      false
    end
  end

  def smtp_delivery?
    ActionMailer::Base.delivery_method == :smtp
  end

  def smtp_starttls_enabled?(settings, port)
    return false if port == 465

    raw = settings[:enable_starttls]
    raw = settings[:enable_starttls_auto] if raw.nil?

    ActiveModel::Type::Boolean.new.cast(raw.nil? || raw)
  end
end
