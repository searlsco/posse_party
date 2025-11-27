class ApplicationMailer < ActionMailer::Base
  default from: ENV["MAIL_FROM_ADDRESS"].presence || "possy@posseparty.com"
  layout "mailer"
end
