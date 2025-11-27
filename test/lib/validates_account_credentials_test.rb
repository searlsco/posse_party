require "test_helper"

class ValidatesAccountCredentialsTest < ActiveSupport::TestCase
  setup do
    @validator = ValidatesAccountCredentials.new
    @user = users(:user)
  end

  test "validates bsky account with all required credentials" do
    account = @user.accounts.build(
      platform_tag: "bsky",
      label: "Test",
      credentials: {
        "email" => "test@bsky.social",
        "password" => "password123"
      }
    )

    result = @validator.validate(account)

    assert result.success?
    assert_nil result.message
  end

  test "fails validation for bsky account missing email" do
    account = @user.accounts.build(
      platform_tag: "bsky",
      label: "Test",
      credentials: {
        "password" => "password123"
      }
    )

    result = @validator.validate(account)

    refute result.success?
    assert_equal "Missing required credentials: email", result.message
  end

  test "fails validation for bsky account with blank password" do
    account = @user.accounts.build(
      platform_tag: "bsky",
      label: "Test",
      credentials: {
        "email" => "test@bsky.social",
        "password" => ""
      }
    )

    result = @validator.validate(account)

    refute result.success?
    assert_equal "Bluesky requires credential fields: password", result.message
  end

  test "validates x account with all required credentials" do
    account = @user.accounts.build(
      platform_tag: "x",
      label: "Test",
      credentials: {
        "api_key" => "key123",
        "api_key_secret" => "secret123",
        "access_token" => "token123",
        "access_token_secret" => "tokensecret123"
      }
    )

    result = @validator.validate(account)

    assert result.success?
  end

  test "fails validation for x account missing multiple credentials" do
    account = @user.accounts.build(
      platform_tag: "x",
      label: "Test",
      credentials: {
        "api_key" => "key123"
      }
    )

    result = @validator.validate(account)

    refute result.success?
    assert_match(/Missing required credentials:/, result.message)
    assert_match(/api_key_secret/, result.message)
    assert_match(/access_token/, result.message)
    assert_match(/access_token_secret/, result.message)
  end

  test "validates youtube account with all required credentials" do
    account = @user.accounts.build(
      platform_tag: "youtube",
      label: "Test",
      credentials: {
        "client_id" => "client123",
        "client_secret" => "secret123",
        "access_token" => "token123",
        "refresh_token" => "refresh123"
      }
    )

    result = @validator.validate(account)

    assert result.success?
  end

  test "allows system credentials that are not required" do
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

    result = @validator.validate(account)

    assert result.success?
  end

  test "validates linkedin account with all required credentials" do
    account = @user.accounts.build(
      platform_tag: "linkedin",
      label: "Test",
      credentials: {
        "client_id" => "client123",
        "client_secret" => "secret123",
        "access_token" => "token123",
        "person_urn" => "urn:li:person:test123"
      }
    )

    result = @validator.validate(account)

    assert result.success?
  end
end
