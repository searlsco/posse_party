require "aws-sdk-sesv2"

# Simple Action Mailer delivery method that sends via AWS SES V2 HTTPS API using RawEmail.
class SesApiDelivery
  def initialize(_values)
    @client = Aws::SESV2::Client.new
  end

  def deliver!(mail)
    from = Array(mail.from).first
    raise ArgumentError, "Email missing From" unless from

    @client.send_email(
      from_email_address: from,
      destination: {to_addresses: Array(mail.to)},
      content: {raw: {data: mail.to_s}}
    )
  end
end

ActionMailer::Base.add_delivery_method :ses_api, SesApiDelivery
