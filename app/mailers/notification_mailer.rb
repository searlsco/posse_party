class NotificationMailer < ApplicationMailer
  def notify
    @message = params[:message]
    mail(
      to: User.where(admin: true).map(&:email),
      subject: params[:subject].presence || "POSSE Party [#{Rails.env}]"
    )
  end
end
