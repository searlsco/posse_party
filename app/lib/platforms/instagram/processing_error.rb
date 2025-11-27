class Platforms::Instagram
  # Raised when an IG container transitions to an error/unknown processing state
  class ProcessingError < StandardError
    def initialize(container_id:, code:, subcode: nil, raw: nil)
      @container_id = container_id
      @code = code&.to_s
      @subcode = subcode&.to_s
      @raw = raw
      @base_message = "Instagram container #{container_id} not processed successfully (status_code=#{code}, status=#{subcode})"
      super(@base_message)
    end

    attr_reader :code, :subcode, :container_id, :raw

    def to_s
      details = [
        ("container_id=#{container_id}" if container_id),
        ("status_code=#{code}" if code),
        ("status=#{subcode}" if subcode)
      ].compact
      [@base_message, ("(#{details.join(", ")})" if details.any?)].compact.join(" ")
    end
  end
end
