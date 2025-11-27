require "net/http"
require "uri"
require "json"
require "base64"

module MailDelivery
  class BaseHttpDelivery
    DEFAULT_TIMEOUT = 5

    def initialize(_settings = {})
    end

    def deliver!(mail)
      raise "Attachments are not supported by HTTP mailers yet." if mail.attachments.present?

      perform_request(payload_from(mail))
    end

    private

    def payload_from(mail)
      {
        from: from_address(mail),
        reply_to: reply_to_address(mail),
        to: compact_addresses(mail.to),
        cc: compact_addresses(mail.cc),
        bcc: compact_addresses(mail.bcc),
        subject: mail.subject.to_s,
        text: text_body(mail),
        html: html_body(mail)
      }.compact
    end

    def from_address(mail)
      Array(mail[:from]&.formatted).first || Array(mail.from).first
    end

    def reply_to_address(mail)
      Array(mail[:reply_to]&.formatted).first || Array(mail.reply_to).first
    end

    def compact_addresses(addresses)
      Array(addresses).compact_blank
    end

    def text_body(mail)
      if mail.text_part
        mail.text_part.decoded
      elsif mail.multipart?
        nil
      else
        html_content?(mail) ? nil : mail.body.decoded
      end
    end

    def html_body(mail)
      if mail.html_part
        mail.html_part.decoded
      elsif html_content?(mail)
        mail.body.decoded
      end
    end

    def html_content?(mail)
      mail.mime_type&.include?("html")
    end

    def https_post(uri, headers:, body:, json: true)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = DEFAULT_TIMEOUT
      http.read_timeout = DEFAULT_TIMEOUT

      request_class = Net::HTTP::Post
      request = request_class.new(uri.request_uri)
      headers.each { |k, v| request[k] = v }

      if json
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(body)
      else
        request.set_form_data(body)
      end

      response = http.request(request)
      unless response.is_a?(Net::HTTPSuccess)
        raise "#{self.class.name} HTTP #{response.code}: #{response.body.to_s[0, 200]}"
      end
    end
  end
end
