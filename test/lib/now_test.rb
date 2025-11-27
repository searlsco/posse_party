require "test_helper"

class NowTest < ActiveSupport::TestCase
  def test_normal_now
    assert_in_delta Time.current, Now.time, 1.second
    assert_equal Date.current, Now.date
  end

  def test_overridden_time
    fake_start_time = 1.month.ago
    Now.override!(fake_start_time)

    assert_in_delta fake_start_time, Now.time, 1.second
    assert_equal fake_start_time.to_date, Now.date
    refute_equal fake_start_time, Now.time

    Now.reset!
    assert_in_delta Time.current, Now.time, 1.second
    assert_equal Date.current, Now.date

    Now.override!(fake_start_time, freeze: true)

    assert_equal fake_start_time, Now.time

    Now.reset!
    SystemConfiguration.instance.update!(fake_now: 1.year.ago)
    assert_in_delta 1.year.ago, Now.time, 1.second
    SystemConfiguration.instance.update!(fake_now: nil)

    Now.reset!
    refute_equal Time.current, Now.time
    assert_in_delta Time.current, Now.time, 1.second
  end
end
