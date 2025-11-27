require "test_helper"

class Platforms::Linkedin::ExchangesShortLivedLinkedinTokenTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @subject = Platforms::Linkedin::ExchangesShortLivedLinkedinToken.new
    @user = users(:user)
    @account = @user.accounts.create!(
      platform_tag: "linkedin",
      label: "Test LinkedIn",
      credentials: {
        "client_id" => "test_client_id",
        "client_secret" => "test_client_secret",
        "access_token" => "test_access_token",
        "person_urn" => "urn:li:person:TestPerson"
      }
    )
  end

  def test_calculate_expires_at_returns_iso8601_string
    fake_time = Time.zone.parse("2025-01-01T10:00:00Z")
    Now.override!(fake_time, freeze: true)

    expires_at = @subject.send(:calculate_expires_at, 3600)

    assert expires_at.is_a?(String), "expires_at should be a string, got #{expires_at.class}"
    assert_equal "2025-01-01T11:00:00Z", expires_at

    parsed_time = Time.zone.parse(expires_at)
    expected_time = fake_time + 3600.seconds
    assert_equal expected_time, parsed_time
  end

  def test_calculate_expires_at_handles_nil_input
    expires_at = @subject.send(:calculate_expires_at, nil)
    assert_nil expires_at
  end

  def test_calculate_expires_at_handles_non_numeric_input
    expires_at = @subject.send(:calculate_expires_at, "not_a_number")
    assert_nil expires_at
  end
end
