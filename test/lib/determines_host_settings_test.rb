require "test_helper"

class DeterminesHostSettingsTest < ActiveSupport::TestCase
  def test_disables_ssl_for_ipv4_host
    settings = determine(app_host: "174.138.84.37")

    assert_equal "http", settings.protocol
    refute settings.force_ssl
    refute settings.cookies_secure
  end

  def test_prefers_https_for_private_host_even_when_ip
    settings = determine(app_host: "10.0.0.5", app_private_host: true)

    assert_equal "https", settings.protocol
    refute settings.force_ssl
    refute settings.cookies_secure
  end

  def test_respects_app_protocol_http
    settings = determine(app_host: "example.com", app_protocol_env: "http")

    assert_equal "http", settings.protocol
    refute settings.force_ssl
    refute settings.cookies_secure
  end

  def test_defaults_to_https_for_domain
    settings = determine(app_host: "example.com")

    assert_equal "https", settings.protocol
    assert settings.force_ssl
    assert settings.cookies_secure
  end

  def test_uses_http_when_host_missing
    settings = determine(app_host: nil)

    assert_equal "http", settings.protocol
    refute settings.force_ssl
    refute settings.cookies_secure
  end

  def test_disables_ssl_when_app_port_overrides_80
    settings = determine(app_host: "example.com", app_port: "8080")

    assert_equal "http", settings.protocol
    refute settings.force_ssl
    refute settings.cookies_secure
  end

  private

  def determine(app_host:, app_private_host: false, app_port: nil, app_protocol_env: nil)
    DeterminesHostSettings.new.determine(
      app_host: app_host,
      app_private_host: app_private_host,
      app_port: app_port,
      app_protocol_env: app_protocol_env
    )
  end
end
