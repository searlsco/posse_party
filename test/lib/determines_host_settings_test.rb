require "test_helper"

class DeterminesHostSettingsTest < ActiveSupport::TestCase
  def teardown
    ENV.delete("FORCE_SSL")
  end

  def test_defaults_to_http_without_app_host
    result = DeterminesHostSettings.new.determine(
      app_host: nil,
      app_private_host: false,
      app_protocol_env: nil
    )

    assert_equal "http", result.protocol
    assert_equal false, result.force_ssl
  end

  def test_hostname_defaults_to_https_and_force_ssl
    result = DeterminesHostSettings.new.determine(
      app_host: "app.posseparty.com",
      app_private_host: false,
      app_protocol_env: nil
    )

    assert_equal "https", result.protocol
    assert_equal true, result.force_ssl
  end

  def test_force_ssl_false_disables_redirect_but_keeps_https
    ENV["FORCE_SSL"] = "false"

    result = DeterminesHostSettings.new.determine(
      app_host: "app.posseparty.com",
      app_private_host: false,
      app_protocol_env: nil
    )

    assert_equal "https", result.protocol
    assert_equal false, result.force_ssl
  end

  def test_ip_host_defaults_to_http_without_ssl
    result = DeterminesHostSettings.new.determine(
      app_host: "192.168.1.24",
      app_private_host: false,
      app_protocol_env: nil
    )

    assert_equal "http", result.protocol
    assert_equal false, result.force_ssl
  end

  def test_private_host_defaults_to_https_without_forcing_ssl
    result = DeterminesHostSettings.new.determine(
      app_host: "nas.local",
      app_private_host: true,
      app_protocol_env: nil
    )

    assert_equal "https", result.protocol
    assert_equal false, result.force_ssl
  end
end
