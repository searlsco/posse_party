module RelaxedJson
  def self.parse(string, default: nil, symbolize_names: true)
    return default if string.blank?

    JSON.parse(string, symbolize_names: symbolize_names)
  rescue JSON::ParserError
    default
  end
end
