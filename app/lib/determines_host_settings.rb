require_relative "identifies_ip_host"
require_relative "parses_env_boolean"

class DeterminesHostSettings
  Result = Struct.new(:force_ssl, :protocol, :cookies_secure, keyword_init: true)

  def initialize
    @identifies_ip_host = IdentifiesIpHost.new
    @parses_env_boolean = ParsesEnvBoolean.new
  end

  def determine(app_host:, app_private_host:, app_port:, app_protocol_env:)
    host_is_ip = app_host && @identifies_ip_host.identify(app_host)

    protocol = choose_protocol(app_protocol_env, app_private_host, app_port, app_host, host_is_ip)

    force_ssl = choose_force_ssl(protocol, app_private_host, app_host, host_is_ip)

    Result.new(
      force_ssl: force_ssl,
      protocol: protocol,
      cookies_secure: force_ssl
    )
  end

  private

  def choose_protocol(app_protocol_env, app_private_host, app_port, app_host, host_is_ip)
    return app_protocol_env if app_protocol_env
    return "http" unless app_host
    return "http" if app_port && app_port != "80"
    return "https" if app_private_host
    return "http" if host_is_ip

    "https"
  end

  def choose_force_ssl(protocol, app_private_host, app_host, host_is_ip)
    return false if app_private_host
    return false if protocol == "http"
    return false if host_is_ip

    @parses_env_boolean.parse("FORCE_SSL", default: app_host.present?)
  end
end
