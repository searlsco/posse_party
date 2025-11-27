class NotifiesUser
  include Rails.application.routes.url_helpers

  def initialize
    @creates_notification = Notifications::CreatesNotification.new
    @extractor = ExtractsTextFromSimulatedEmail.new
    @email_capability = DeterminesEmailCapability.new
  end

  # Either text must be passed or mail/method must be passed (so as to extract them)
  def notify(user:, severity:, title:, text: nil, mail: nil, method: nil, params: {}, refs: [], badge: false)
    if mail && method
      text, refs = extract_simulated_email_contents(mail, method, params, refs)
    elsif text.nil?
      raise "Either :text or :mail and :method MUST be provided"
    end

    if mail == true && method.nil? && params.blank?
      mail = NotificationMailer
      method = :notify
      params = {subject: title, message: text}
    end

    @creates_notification.create!(user:, title:, severity:, text:, refs:, badge: badge).tap do |notification|
      if @email_capability.determine && mail && method
        mail.with(params.merge(
          message: <<~MSG
            #{params[:message]}

            See notification at: #{log_url(notification)}
          MSG
        )).public_send(method).deliver_later
      end
    end
  end

  private

  def extract_simulated_email_contents(mail, method, params, refs)
    extracted = @extractor.extract(mail:, method:, params:)
    if extracted.text.present?
      [extracted.text, Array(refs) + extracted.refs]
    end
  end
end
