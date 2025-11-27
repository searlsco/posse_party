require "test_helper"

class Platforms::Linkedin::PotentiallyTellsUserToRenewLinkedinAccessTokenTest < ActionMailer::TestCase
  def setup
    @subject = Platforms::Linkedin::PotentiallyTellsUserToRenewLinkedinAccessToken.new
    @user = users(:user)
    @account = @user.accounts.create!(
      platform_tag: "linkedin",
      label: "Test LinkedIn",
      credentials: {
        "client_id" => "test_client_id",
        "client_secret" => "test_client_secret",
        "access_token" => "current_token",
        "person_urn" => "urn:li:person:TestPerson"
      }
    )
  end

  def test_expires_at_soon_returns_true_for_near_expiration
    fake_time = Time.zone.parse("2025-01-01T10:00:00Z")
    Now.override!(fake_time, freeze: true)

    expires_at = (fake_time + 5.days).iso8601
    result = @subject.send(:expires_at_soon?, expires_at)

    assert result, "Should return true for expiration within renewal window"
  end

  def test_expires_at_soon_returns_false_for_far_expiration
    fake_time = Time.zone.parse("2025-01-01T10:00:00Z")
    Now.override!(fake_time, freeze: true)

    expires_at = (fake_time + 15.days).iso8601
    result = @subject.send(:expires_at_soon?, expires_at)

    refute result, "Should return false for expiration outside renewal window"
  end

  def test_expires_at_soon_forces_renewal_for_invalid_date
    result = @subject.send(:expires_at_soon?, "invalid-date")
    assert result, "Should return true for invalid date string to force renewal"
  end

  def test_expires_at_soon_forces_renewal_for_nil
    result = @subject.send(:expires_at_soon?, nil)
    assert result, "Should return true for nil to force renewal"
  end

  def test_expires_at_soon_forces_renewal_for_numeric_input
    expires_at = 5.days.from_now.to_i
    result = @subject.send(:expires_at_soon?, expires_at)
    assert result, "Should return true for numeric input to force renewal and migration"
  end

  def test_within_cooldown_period_returns_true_for_recent_reminder
    fake_time = Time.zone.parse("2025-01-01T10:00:00Z")
    Now.override!(fake_time, freeze: true)

    recent_reminder = (fake_time - 12.hours).iso8601
    result = @subject.send(:within_cooldown_period?, recent_reminder)

    assert result, "Should return true for recent reminder within cooldown"
  end

  def test_within_cooldown_period_returns_false_for_old_reminder
    fake_time = Time.zone.parse("2025-01-01T10:00:00Z")
    Now.override!(fake_time, freeze: true)

    old_reminder = (fake_time - 25.hours).iso8601
    result = @subject.send(:within_cooldown_period?, old_reminder)

    refute result, "Should return false for old reminder outside cooldown"
  end

  def test_within_cooldown_period_handles_nil_gracefully
    result = @subject.send(:within_cooldown_period?, nil)
    refute result, "Should return false for nil reminder date"
  end
end
