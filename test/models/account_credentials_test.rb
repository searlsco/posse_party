require "test_helper"

class AccountCredentialsTest < ActiveSupport::TestCase
  setup do
    @user = New.create(User, email: "test@example.com")
  end

  test "required_credentials returns platform-specific credentials" do
    bsky_account = @user.accounts.build(platform_tag: "bsky", label: "Test")
    assert_equal %w[email password], bsky_account.required_credentials

    x_account = @user.accounts.build(platform_tag: "x", label: "Test")
    assert_equal %w[api_key access_token api_key_secret access_token_secret], x_account.required_credentials

    youtube_account = @user.accounts.build(platform_tag: "youtube", label: "Test")
    assert_equal %w[client_id client_secret access_token refresh_token], youtube_account.required_credentials
  end

  test "system_credentials returns non-required credentials" do
    account = @user.accounts.build(
      platform_tag: "youtube",
      label: "Test",
      credentials: {
        "client_id" => "client123",
        "client_secret" => "secret123",
        "access_token" => "token123",
        "refresh_token" => "refresh123",
        "access_token_expires_at" => "2025-12-31T23:59:59Z",
        "refresh_token_expires_at" => "2025-12-31T23:59:59Z"
      }
    )

    assert_equal %w[access_token_expires_at refresh_token_expires_at], account.system_credentials
  end

  test "system_credentials returns empty array when no system credentials exist" do
    account = @user.accounts.build(
      platform_tag: "bsky",
      label: "Test",
      credentials: {
        "email" => "test@bsky.social",
        "password" => "password123"
      }
    )

    assert_equal [], account.system_credentials
  end

  test "validates presence of platform_tag" do
    account = @user.accounts.build(label: "Test")

    e = assert_raises do
      account.valid?
    end
    assert_includes e.message, "Unsupported platform: nil"
  end

  test "validates presence of label" do
    account = @user.accounts.build(platform_tag: "bsky")

    refute account.valid?
    assert_includes account.errors[:label], "can't be blank"
  end

  test "validates required credentials through custom validator" do
    account = @user.accounts.build(
      platform_tag: "bsky",
      label: "Test",
      credentials: {
        "email" => "test@bsky.social",
        "password" => ""
      }
    )

    refute account.valid?
    assert_includes account.errors.full_messages, "Bluesky requires credential fields: password"
  end

  test "account is valid with all required credentials" do
    account = @user.accounts.build(
      platform_tag: "bsky",
      label: "Test",
      credentials: {
        "email" => "test@bsky.social",
        "password" => "password123"
      }
    )

    assert account.valid?
  end

  test "account is valid with extra system credentials" do
    account = @user.accounts.build(
      platform_tag: "youtube",
      label: "Test",
      credentials: {
        "client_id" => "client123",
        "client_secret" => "secret123",
        "access_token" => "token123",
        "refresh_token" => "refresh123",
        "access_token_expires_at" => "2025-12-31T23:59:59Z"
      }
    )

    assert account.valid?
  end

  test "raises error for unsupported platform" do
    account = @user.accounts.build(
      platform_tag: "unsupported_platform",
      label: "Test"
    )

    matcher = PublishesCrosspost::MatchesPlatformApi.new

    e = assert_raises do
      matcher.match(account)
    end

    assert_includes e.message, "Unsupported platform: \"unsupported_platform\""
  end
end
