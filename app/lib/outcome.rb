class Outcome
  attr_reader :message, :error

  def initialize(success, message, error = nil)
    @success = success
    @message = message
    @error = error
  end

  def self.success(message = nil)
    new(true, message)
  end

  def self.failure(message, error = nil)
    new(false, message, error)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def flash_type
    success? ? :notice : :alert
  end
end
