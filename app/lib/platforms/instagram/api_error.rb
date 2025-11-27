class Platforms::Instagram
  # Raised when the Instagram Graph API returns an error payload
  class ApiError < StandardError
    def initialize(message:, code: nil, subcode: nil, type: nil, fbtrace_id: nil, request: nil, raw: nil)
      @base_message = message
      @code = code&.to_s
      @subcode = subcode&.to_s
      @type = type
      @fbtrace_id = fbtrace_id
      @request = request
      @raw = raw
      super(message)
    end

    attr_reader :code, :subcode, :type, :fbtrace_id, :request, :raw

    def to_s
      details = []
      details << "code=#{code}" if code
      details << "subcode=#{subcode}" if subcode
      details << "type=#{type}" if type
      details << "fbtrace_id=#{fbtrace_id}" if fbtrace_id
      if request
        method = request[:method]&.to_s&.upcase
        path = request[:path]
        details << "request=#{[method, path].compact.join(" ")}" if method || path
      end
      [@base_message, ("(#{details.join(", ")})" if details.any?)].compact.join(" ")
    end
  end
end
