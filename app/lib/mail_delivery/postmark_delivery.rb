module MailDelivery
  class PostmarkDelivery < BaseHttpDelivery
    ENDPOINT = URI("https://api.postmarkapp.com/email")

    def deliver!(mail)
      api_token = ENV["POSTMARK_API_TOKEN"].to_s
      raise "POSTMARK_API_TOKEN is missing" if api_token.blank?

      payload = payload_from(mail)
      payload[:from] ||= ENV["MAIL_FROM_ADDRESS"].to_s

      https_post(
        ENDPOINT,
        headers: {
          "X-Postmark-Server-Token" => api_token
        },
        body: postmark_payload(payload),
        json: true
      )
    end

    private

    def postmark_payload(payload)
      {
        From: payload[:from],
        To: payload[:to]&.join(","),
        Cc: payload[:cc]&.join(","),
        Bcc: payload[:bcc]&.join(","),
        ReplyTo: payload[:reply_to],
        Subject: payload[:subject],
        TextBody: payload[:text],
        HtmlBody: payload[:html]
      }.compact
    end
  end
end
