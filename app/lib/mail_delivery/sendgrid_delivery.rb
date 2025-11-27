module MailDelivery
  class SendgridDelivery < BaseHttpDelivery
    ENDPOINT = URI("https://api.sendgrid.com/v3/mail/send")

    def deliver!(mail)
      api_key = ENV["SENDGRID_API_KEY"].to_s
      raise "SENDGRID_API_KEY is missing" if api_key.blank?

      payload = sendgrid_payload(payload_from(mail))

      https_post(
        ENDPOINT,
        headers: {"Authorization" => "Bearer #{api_key}"},
        body: payload,
        json: true
      )
    end

    private

    def sendgrid_payload(payload)
      {
        from: email_hash(payload[:from] || ENV["MAIL_FROM_ADDRESS"].to_s),
        reply_to: reply_to_hash(payload[:reply_to]),
        personalizations: [personalization(payload)],
        subject: payload[:subject],
        content: sendgrid_content(payload[:text], payload[:html])
      }.compact
    end

    def personalization(payload)
      {
        to: email_hashes(payload[:to]),
        cc: email_hashes(payload[:cc]),
        bcc: email_hashes(payload[:bcc])
      }.compact
    end

    def email_hashes(addresses)
      return nil if addresses.blank?

      addresses.map { |email| email_hash(email) }
    end

    def email_hash(email)
      {email: email}
    end

    def reply_to_hash(email)
      return nil if email.blank?

      {email: email}
    end

    def sendgrid_content(text, html)
      contents = []
      contents << {type: "text/plain", value: text} if text.present?
      contents << {type: "text/html", value: html} if html.present?
      contents.presence
    end
  end
end
