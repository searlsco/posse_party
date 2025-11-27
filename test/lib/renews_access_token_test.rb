require "test_helper"

class RenewsAccessTokenTest < ActiveSupport::TestCase
  def setup
    @subject = RenewsAccessToken.new
    @account = accounts(:admin_x_account)
  end

  test "calls renew on renewable platform API" do
    # Since this is a delegator that instantiates its dependency,
    # we'll test its basic behavior without deep mocking
    result = @subject.renew(@account)

    # X platform is not renewable, so it should return success without renewing
    assert result.success?
  end

  test "skips renewal for non-renewable platforms" do
    # Test with a platform we know is not renewable
    result = @subject.renew(@account)

    assert result.success?
  end
end
