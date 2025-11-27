require "test_helper"

class EnvChecksLibidnCheckTest < ActiveSupport::TestCase
  def test_passes_when_idn_is_available
    check = EnvChecks::LibidnCheck.new
    assert check.check(require_fn: ->(_name) { true })
  end

  def test_raises_clear_message_when_idn_is_missing
    check = EnvChecks::LibidnCheck.new
    error = assert_raises(RuntimeError) { check.check(require_fn: ->(_name) { raise LoadError }) }
    assert_includes error.message, "Missing libidn system library"
    assert_includes error.message, "idn-ruby"
    assert_includes error.message, "twitter-text"
  end
end
