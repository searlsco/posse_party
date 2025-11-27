require "test_helper"

class ChecksSystemStatusTest < ActiveSupport::TestCase
  setup do
    Thread.current[ChecksSystemStatus::CACHE_KEY] = nil
    Now.override!(Time.current.change(usec: 0), freeze: true)
  end

  teardown do
    Thread.current[ChecksSystemStatus::CACHE_KEY] = nil
    Now.reset!
  end

  test "caches status for thirty minutes and expires afterward" do
    checker = ChecksSystemStatus.new

    first = checker.check
    assert_kind_of ChecksSystemStatus::StatusVerification, first

    advance_now 1.second
    assert_same first, checker.check

    advance_now 1.second
    uncached = checker.check(cache: false)
    assert_operator uncached.checked_at, :>, first.checked_at

    advance_now 1.second
    assert_same first, checker.check

    advance_now 31.minutes
    after_expiry = checker.check
    assert_operator after_expiry.checked_at, :>, first.checked_at
  end

  private

  def advance_now(duration)
    Now.override!(Now.time + duration, freeze: true)
  end
end
