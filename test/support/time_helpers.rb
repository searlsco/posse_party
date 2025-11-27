module TimeHelpers
  def fake_time!(time = Time.current, freeze: false, &blk)
    time = time.is_a?(Time) ? time : Time.zone.parse(time)
    fake_time = Time.zone.parse(time.iso8601(3))
    Now.override!(fake_time, freeze:)
    blk.call(fake_time)
    Now.reset!
  end
end
