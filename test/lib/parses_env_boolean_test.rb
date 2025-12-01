require "test_helper"

class ParsesEnvBooleanTest < ActiveSupport::TestCase
  def test_casts_common_boolean_strings
    ENV["SAMPLE_BOOL"] = "false"

    parser = ParsesEnvBoolean.new

    assert_equal false, parser.parse("SAMPLE_BOOL", default: true)
  ensure
    ENV.delete("SAMPLE_BOOL")
  end

  def test_uses_default_when_variable_is_unset
    parser = ParsesEnvBoolean.new

    assert_equal true, parser.parse("MISSING_BOOL", default: true)
  end

  def test_uses_default_when_variable_is_blank
    ENV["BLANK_BOOL"] = ""

    parser = ParsesEnvBoolean.new

    assert_equal true, parser.parse("BLANK_BOOL", default: true)
  ensure
    ENV.delete("BLANK_BOOL")
  end
end
