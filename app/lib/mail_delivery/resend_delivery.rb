module MailDelivery
  class ResendDelivery < BaseHttpDelivery
    ENDPOINT = URI("https://api.resend.com/emails")

    def deliver!(mail)
      api_key = ENV["RESEND_API_KEY"].to_s
      raise "RESEND_API_KEY is missing" if api_key.blank?

      payload = payload_from(mail)
      payload[:from] ||= ENV["MAIL_FROM_ADDRESS"].to_s

      https_post(
        ENDPOINT,
        headers: {"Authorization" => "Bearer #{api_key}"},
        body: payload,
        json: true
      )
    end
  end
end
