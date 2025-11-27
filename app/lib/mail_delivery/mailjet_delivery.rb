module MailDelivery
  class MailjetDelivery < BaseHttpDelivery
    ENDPOINT = URI("https://api.mailjet.com/v3.1/send")

    def deliver!(mail)
      api_key = ENV["MAILJET_API_KEY"].to_s
      api_secret = ENV["MAILJET_API_SECRET"].to_s
      raise "MAILJET_API_KEY is missing" if api_key.blank?
      raise "MAILJET_API_SECRET is missing" if api_secret.blank?

      payload = payload_from(mail)
      payload[:from] ||= ENV["MAIL_FROM_ADDRESS"].to_s

      https_post(
        ENDPOINT,
        headers: {"Authorization" => "Basic #{Base64.strict_encode64("#{api_key}:#{api_secret}")}"},
        body: mailjet_payload(payload),
        json: true
      )
    end

    private

    def mailjet_payload(payload)
      message = {
        From: email_hash(payload[:from]),
        To: email_hashes(payload[:to]),
        Cc: email_hashes(payload[:cc]),
        Bcc: email_hashes(payload[:bcc]),
        Subject: payload[:subject],
        TextPart: payload[:text],
        HTMLPart: payload[:html],
        ReplyTo: payload[:reply_to].present? ? email_hash(payload[:reply_to]) : nil
      }.compact

      {Messages: [message]}
    end

    def email_hashes(addresses)
      return nil if addresses.blank?

      addresses.map { |email| email_hash(email) }
    end

    def email_hash(email)
      {Email: email}
    end
  end
end
