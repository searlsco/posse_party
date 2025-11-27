require "test_helper"
require "mocktail"

class RegeneratesApiKeyTest < ActiveSupport::TestCase
  def setup
    @user = users(:user)
    @subject = RegeneratesApiKey.new
  end

  test "regenerates api key for user successfully" do
    old_key = @user.api_key

    result = @subject.regenerate(@user)

    assert result.success?
    assert_equal "API key regenerated successfully", result.message
    assert_not_equal old_key, @user.reload.api_key
    assert_match(/^[a-f0-9]{64}$/, @user.api_key)
  end

  test "returns failure when user cannot be saved" do
    user = users(:user)
    # Force save to fail by making the record invalid
    user.email = nil

    result = @subject.regenerate(user)

    assert_not result.success?
    assert_equal "Failed to regenerate API key", result.message
  end

  test "generates a new 64-character hex key" do
    result = @subject.regenerate(@user)

    assert result.success?
    assert_equal 64, @user.reload.api_key.length
    assert @user.api_key.match?(/^[a-f0-9]+$/)
  end
end
