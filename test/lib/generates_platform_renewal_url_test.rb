require "test_helper"

class GeneratesPlatformRenewalUrlTest < ActiveSupport::TestCase
  setup do
    @matches_platform_api = Mocktail.of_next(PublishesCrosspost::MatchesPlatformApi)
    @generates_oauth_state = Mocktail.of_next(GeneratesOauthState)
    @subject = GeneratesPlatformRenewalUrl.new
  end

  def test_generate_returns_platform_renewal_url
    platform = Mocktail.of(Platforms::Base)
    stubs { @matches_platform_api.match(:some_account) }.with { platform }
    stubs { @generates_oauth_state.generate(:some_account) }.with { "STATE123" }
    stubs { platform.renewable? }.with { true }
    stubs { platform.renewal_url_supported? }.with { true }
    stubs { platform.renewal_url(:some_account, "STATE123") }.with { :some_url }

    result = @subject.generate(:some_account)

    assert result.success?
    assert_equal :some_url, result.data
  end

  def test_generate_handles_nonrenewable_platform
    account = Account.new(platform_tag: :bsky)
    platform = Mocktail.of(Platforms::Base)
    stubs { @matches_platform_api.match(account) }.with { platform }
    stubs { platform.renewable? }.with { true }
    stubs { platform.renewal_url_supported? }.with { false }

    result = @subject.generate(account)

    assert result.failure?
    assert_equal "Credential renewal unsupported for Bluesky", result.error
    verify_never_called { @generates_oauth_state.generate }
  end
end
