require "test_helper"

class OutcomeTest < ActiveSupport::TestCase
  test "creates successful outcome" do
    outcome = Outcome.success("Operation completed")

    assert outcome.success?
    assert_not outcome.failure?
    assert_equal "Operation completed", outcome.message
    assert_nil outcome.error
  end

  test "creates successful outcome without message" do
    outcome = Outcome.success

    assert outcome.success?
    assert_not outcome.failure?
    assert_nil outcome.message
    assert_nil outcome.error
  end

  test "creates failure outcome with message only" do
    outcome = Outcome.failure("Something went wrong")

    assert outcome.failure?
    assert_not outcome.success?
    assert_equal "Something went wrong", outcome.message
    assert_nil outcome.error
  end

  test "creates failure outcome with message and error" do
    error = StandardError.new("Oops")
    outcome = Outcome.failure("Something went wrong", error)

    assert outcome.failure?
    assert_not outcome.success?
    assert_equal "Something went wrong", outcome.message
    assert_equal error, outcome.error
  end
end
