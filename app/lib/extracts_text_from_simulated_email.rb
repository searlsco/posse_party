class ExtractsTextFromSimulatedEmail
  Result = Struct.new(:text, :refs, keyword_init: true)

  def extract(mail:, method:, params: {})
    preview = mail.with(params).public_send(method)
    return Result.new(text: nil, refs: []) unless preview.respond_to?(:message)

    message = preview.message
    text = if message.respond_to?(:text_part) && message.text_part
      message.text_part.decoded
    elsif message.respond_to?(:content_type) && message.content_type&.include?("text/plain") && message.respond_to?(:body)
      message.body.decoded
    elsif message.respond_to?(:html_part) && message.html_part
      message.html_part.decoded
    end

    return Result.new(text: nil, refs: []) if text.blank?

    urls = text.scan(%r{https?://[^\s<]+})
    refs = urls.map { |u| {"url" => u} }
    Result.new(text:, refs:)
  end
end
