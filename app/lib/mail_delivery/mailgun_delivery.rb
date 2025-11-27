module MailDelivery
  class MailgunDelivery < BaseHttpDelivery
    def deliver!(mail)
      api_key = ENV["MAILGUN_API_KEY"].to_s
      domain = ENV["MAILGUN_DOMAIN"].to_s
      raise "MAILGUN_API_KEY is missing" if api_key.blank?
      raise "MAILGUN_DOMAIN is missing" if domain.blank?

      payload = payload_from(mail)
      payload[:from] ||= ENV["MAIL_FROM_ADDRESS"].to_s

      endpoint = URI("https://api.mailgun.net/v3/#{domain}/messages")

      https_post(
        endpoint,
        headers: {"Authorization" => "Basic #{Base64.strict_encode64("api:#{api_key}")}"},
        body: form_payload(payload),
        json: false
      )
    end

    private

    def form_payload(payload)
      {
        :from => payload[:from],
        :to => payload[:to]&.join(","),
        :cc => payload[:cc]&.join(","),
        :bcc => payload[:bcc]&.join(","),
        :subject => payload[:subject],
        :text => payload[:text],
        :html => payload[:html],
        "h:Reply-To" => payload[:reply_to]
      }.compact
    end
  end
end
