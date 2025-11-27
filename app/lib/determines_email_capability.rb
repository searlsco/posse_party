class DeterminesEmailCapability
  def determine
    if smtp_configured?
      true
    elsif Rails.configuration.action_mailer.delivery_method == :letter_opener
      true
    elsif Rails.env.test? && Rails.configuration.action_mailer.delivery_method == :test
      true
    else
      false
    end
  end

  private

  def smtp_configured?
    settings = ActionMailer::Base.smtp_settings || {}

    address = settings[:address].presence
    return false if address.blank?

    user = settings[:user_name].to_s
    pass = settings[:password].to_s
    return false if (user.present? && pass.blank?) || (pass.present? && user.blank?)

    true
  end
end
