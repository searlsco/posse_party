require "test_helper"

class IdentifiesIpHostTest < ActiveSupport::TestCase
  def test_detects_ipv4
    assert IdentifiesIpHost.new.identify("192.168.0.1")
  end

  def test_detects_ipv6
    assert IdentifiesIpHost.new.identify("2001:0db8::1")
  end

  def test_rejects_hostnames
    refute IdentifiesIpHost.new.identify("example.com")
  end
end
