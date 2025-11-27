class ChecksSystemStatus
  CACHE_KEY = :checks_system_status_verification
  CACHE_DURATION = 30.minutes

  StatusVerification = Struct.new(
    :smtp_configured,
    :smtp_connected,
    :smtp_error,
    :database_connected,
    :database_error,
    :worker_connected,
    :worker_error,
    :checked_at,
    keyword_init: true
  ) do
    def overall
      return :red if smtp_configured && smtp_connected == false
      return :red unless database_connected && worker_connected
      return :yellow unless smtp_configured

      :green
    end

    def fresh_since?(time)
      checked_at >= time
    end
  end

  def initialize
    @verifies_smtp_connection = VerifiesSmtpConnection.new
  end

  def check(cache: true)
    return cached_verification if cache && fresh_cached?

    verification = build_verification
    cache_verification(verification) if cache
    verification
  end

  private

  def cached_verification
    Thread.current[CACHE_KEY]
  end

  def fresh_cached?
    cached = cached_verification
    cached&.fresh_since?(Now.time - CACHE_DURATION)
  end

  def cache_verification(verification)
    Thread.current[CACHE_KEY] = verification
  end

  def build_verification
    smtp_result = @verifies_smtp_connection.verify
    database_connected, database_error = verify_database
    worker_connected, worker_error = verify_worker

    StatusVerification.new(
      smtp_configured: smtp_result.configured?,
      smtp_connected: smtp_result.connected?,
      smtp_error: smtp_result.error,
      database_connected:,
      database_error:,
      worker_connected:,
      worker_error:,
      checked_at: Now.time
    )
  end

  def verify_database
    ActiveRecord::Base.connection.execute("SELECT 1")
    [true, nil]
  rescue => error
    [false, "#{error.class}: #{error.message}"]
  end

  def verify_worker
    require "solid_queue"
    threshold = 60.seconds.ago
    connected = SolidQueue::Process.where("last_heartbeat_at > ?", threshold).exists?
    [connected, nil]
  rescue => error
    [false, "#{error.class}: #{error.message}"]
  end
end
