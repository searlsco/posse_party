require "ipaddr"

class IdentifiesIpHost
  def initialize
    @ip_parser = IPAddr
  end

  def identify(value)
    !!@ip_parser.new(value)
  rescue IPAddr::InvalidAddressError
    false
  end
end
