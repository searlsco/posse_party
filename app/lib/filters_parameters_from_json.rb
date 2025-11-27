class FiltersParametersFromJson
  def self.filter(json)
    new(json).filter
  end

  def initialize(json)
    @json = json
  end

  def filter
    return "" if @json.blank?

    filtered_payload = parameter_filter.filter(parsed_json)

    return "" if filtered_payload.blank?

    case filtered_payload
    when Hash, Array
      JSON.pretty_generate(filtered_payload)
    else
      filtered_payload.to_s
    end
  rescue JSON::ParserError
    ""
  end

  private

  def parsed_json
    @parsed_json ||= JSON.parse(@json)
  end

  def parameter_filter
    @parameter_filter ||= ActiveSupport::ParameterFilter.new(filter_tokens)
  end

  def filter_tokens
    Array(Rails.application.config.filter_parameters)
  end
end
