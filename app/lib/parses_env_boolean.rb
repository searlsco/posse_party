class ParsesEnvBoolean
  def initialize
    @boolean_type = ActiveModel::Type::Boolean.new
  end

  def parse(key, default:)
    @boolean_type.cast(ENV.fetch(key) { default })
  end
end
