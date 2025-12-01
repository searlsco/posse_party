class ParsesEnvBoolean
  def initialize
    @boolean_type = ActiveModel::Type::Boolean.new
  end

  def parse(key, default:)
    raw = ENV.fetch(key, nil)
    return default if raw.nil? || raw == ""

    @boolean_type.cast(raw)
  end
end
