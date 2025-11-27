require "test_helper"

class ResultTest < ActiveSupport::TestCase
  test "creates successful result with data" do
    data = ["item1", "item2"]
    result = Result.success(data)

    assert result.success?
    assert_not result.failure?
    assert_equal data, result.data
    assert_nil result.error
  end

  test "creates failure result with error" do
    error = "Something went wrong"
    result = Result.failure(error)

    assert result.failure?
    assert_not result.success?
    assert_nil result.data
    assert_equal error, result.error
  end
end
