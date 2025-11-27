module MailDelivery
  class BrevoDelivery < BaseHttpDelivery
    ENDPOINT = URI("https://api.brevo.com/v3/smtp/email")

    def deliver!(mail)
      api_key = ENV["BREVO_API_KEY"].to_s
      raise "BREVO_API_KEY is missing" if api_key.blank?

      payload = payload_from(mail)
      payload[:from] ||= ENV["MAIL_FROM_ADDRESS"].to_s

      https_post(
        ENDPOINT,
        headers: {"api-key" => api_key},
        body: brevo_payload(payload),
        json: true
      )
    end

    private

    def brevo_payload(payload)
      {
        sender: {email: payload[:from]},
        to: array_of_email_hashes(payload[:to]),
        cc: array_of_email_hashes(payload[:cc]),
        bcc: array_of_email_hashes(payload[:bcc]),
        replyTo: payload[:reply_to].present? ? {email: payload[:reply_to]} : nil,
        subject: payload[:subject],
        textContent: payload[:text],
        htmlContent: payload[:html]
      }.compact
    end

    def array_of_email_hashes(addresses)
      return nil if addresses.blank?

      addresses.map { |email| {email: email} }
    end
  end
end
