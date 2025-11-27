class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked
  retry_on StandardError, wait: :polynomially_longer, attempts: Constants::DEFAULT_JOB_RETRIES

  discard_on ActiveJob::DeserializationError

  after_discard do |job, error|
    HandlesJobError.new.call(job, error)
  end
end
