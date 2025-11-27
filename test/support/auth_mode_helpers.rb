module AuthModeHelpers
  def with_smtp_available(overrides = {})
    settings = {
      address: overrides.fetch(:SMTP_HOST, "smtp.example.com"),
      user_name: overrides.fetch(:smtp_username, "user"),
      password: overrides.fetch(:smtp_password, "pass"),
      port: overrides.fetch(:smtp_port, 587),
      enable_starttls: overrides.fetch(:smtp_enable_starttls, true)
    }

    with_smtp_config(settings) { yield }
  end

  def with_smtp_unavailable
    with_smtp_config(nil, delivery_method: :smtp) { yield }
  end

  private

  def with_smtp_config(settings, delivery_method: nil)
    original_smtp_settings = ActionMailer::Base.smtp_settings
    original_config_smtp_settings = Rails.configuration.action_mailer.smtp_settings
    previous_adapter = ActiveJob::Base.queue_adapter
    original_delivery_method = Rails.configuration.action_mailer.delivery_method
    original_mailer_delivery_method = ActionMailer::Base.delivery_method

    if delivery_method
      Rails.configuration.action_mailer.delivery_method = delivery_method
      ActionMailer::Base.delivery_method = delivery_method
    end

    normalized_settings = settings ? settings.symbolize_keys : {}
    ActionMailer::Base.smtp_settings = normalized_settings
    Rails.configuration.action_mailer.smtp_settings = normalized_settings

    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    ConfiguresSearlsAuth.configure
    yield
  ensure
    ActiveJob::Base.queue_adapter = previous_adapter
    if delivery_method
      Rails.configuration.action_mailer.delivery_method = original_delivery_method
      ActionMailer::Base.delivery_method = original_mailer_delivery_method
    end
    ActionMailer::Base.smtp_settings = original_smtp_settings
    Rails.configuration.action_mailer.smtp_settings = original_config_smtp_settings
    ConfiguresSearlsAuth.configure
  end
end
