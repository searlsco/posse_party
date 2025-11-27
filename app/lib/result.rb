class Result
  attr_reader :data, :error

  def initialize(success, data, error = nil)
    @success = success
    @data = data
    @error = error
  end

  def self.success(data)
    new(true, data)
  end

  def self.failure(error)
    new(false, nil, error)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
