class Now
  def self.instance
    @instance ||= Now.new
  end

  def self.override!(fake_start_time, freeze: false, yes_i_know_even_in_production: false)
    raise "Overriding time is not allowed in production!" if Rails.env.production? && !yes_i_know_even_in_production
    @instance = Now.new(fake_start_time, freeze)
  end

  def self.reset!
    @instance = Now.new
  end

  def self.time
    instance.time
  end

  def self.time_in_zone(zone)
    instance.time_in_zone(zone)
  end

  def self.date
    instance.date
  end

  def self.date_in_zone(zone)
    instance.date_in_zone(zone)
  end

  def self.ago(duration)
    instance.ago(duration)
  end

  def self.from_now(duration)
    instance.from_now(duration)
  end

  def self.use_zone(zone, &)
    instance.use_zone(zone, &)
  end

  def initialize(fake_start_time = nil, freeze = false)
    @fake_start_time = fake_start_time
    @freeze_fake_time = freeze
    @actual_start_time = Time.current
    @time_zone = Time.find_zone!("UTC")
  end

  def time
    the_time = if @fake_start_time.present?
      elapsed_time = @freeze_fake_time ? 0 : Time.current - @actual_start_time
      @fake_start_time + elapsed_time
    elsif !Rails.env.production? && SystemConfiguration.instance.fake_now.present?
      elapsed_time = @freeze_fake_time ? 0 : Time.current - SystemConfiguration.instance.updated_at
      SystemConfiguration.instance.fake_now + elapsed_time
    else
      Time.current
    end

    the_time.in_time_zone(@time_zone)
  end

  def time_in_zone(zone)
    use_zone(zone) { time }
  end

  def date
    time.to_date
  end

  def date_in_zone(zone)
    use_zone(zone) { date }
  end

  def ago(duration)
    time - duration
  end

  def from_now(duration)
    time + duration
  end

  def use_zone(zone, &blk)
    new_zone = Time.find_zone!(zone)
    begin
      old_zone, @time_zone = @time_zone, new_zone
      yield
    ensure
      @time_zone = old_zone
    end
  end
end
