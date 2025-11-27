class NotifiesAdmins
  def initialize(logger: Rails.logger)
    @logger = logger
    @notifies_user = NotifiesUser.new
  end

  def call(subject:, body:, severity: "warn", badge: true, refs: [])
    @logger.public_send((severity == "danger") ? :error : :info, subject)
    User.where(admin: true).find_each do |user|
      @notifies_user.notify(
        mail: NotificationMailer,
        method: :notify,
        params: {subject: subject, message: body},
        user: user,
        title: subject,
        severity: severity,
        text: body,
        refs: refs,
        badge: badge
      )
    end
  end
end
