require "test_helper"

class RequiredCredentialsTest < ActiveSupport::TestCase
  test "all platform classes have required_credentials method" do
    platforms = [
      Platforms::Bsky,
      Platforms::X,
      Platforms::Mastodon,
      Platforms::Threads,
      Platforms::Instagram,
      Platforms::Facebook,
      Platforms::Linkedin,
      Platforms::Youtube
    ]

    platforms.each do |platform_class|
      platform = platform_class.new
      assert_respond_to platform, :required_credentials, "#{platform_class} should respond to required_credentials"

      credentials = platform.required_credentials
      assert_kind_of Array, credentials, "#{platform_class}#required_credentials should return an Array"
      assert credentials.all? { |cred| cred.is_a?(String) }, "#{platform_class}#required_credentials should return Array of Strings"
      refute_empty credentials, "#{platform_class}#required_credentials should not be empty"
    end
  end

  test "bsky required credentials" do
    platform = Platforms::Bsky.new
    assert_equal %w[email password], platform.required_credentials
  end

  test "x required credentials" do
    platform = Platforms::X.new
    assert_equal %w[api_key access_token api_key_secret access_token_secret], platform.required_credentials
  end

  test "mastodon required credentials" do
    platform = Platforms::Mastodon.new
    assert_equal %w[base_url access_token], platform.required_credentials
  end

  test "threads required credentials" do
    platform = Platforms::Threads.new
    assert_equal %w[access_token], platform.required_credentials
  end

  test "instagram required credentials" do
    platform = Platforms::Instagram.new
    assert_equal %w[app_id app_secret user_id access_token], platform.required_credentials
  end

  test "facebook required credentials" do
    platform = Platforms::Facebook.new
    assert_equal %w[page_id page_access_token], platform.required_credentials
  end

  test "linkedin required credentials" do
    platform = Platforms::Linkedin.new
    assert_equal %w[client_id access_token client_secret person_urn], platform.required_credentials
  end

  test "youtube required credentials" do
    platform = Platforms::Youtube.new
    assert_equal %w[client_id client_secret access_token refresh_token], platform.required_credentials
  end
end
