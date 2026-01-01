unless ENV["CI"] || ENV["SKIP_COVERAGE"]
  require "simplecov"
  SimpleCov.start "rails"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "vcr"
require_relative "support/new"
require_relative "support/feed_helpers"
require_relative "support/time_helpers"
require_relative "support/vcr_helpers"
require_relative "support/auth_helper"

module ActiveSupport
  class TestCase
    make_my_diffs_pretty!

    self.use_transactional_tests = true

    include TimeHelpers
    include VcrHelpers
    include Mocktail::DSL
    include FeedHelpers

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    setup do
      ActionMailer::Base.deliveries.clear
    end

    teardown do
      Now.reset!
      Mocktail.reset
    end

    def verify(...)
      assert true
      Mocktail.verify(...)
    end

    def verify_never_called(&blk)
      verify(times: 0, ignore_extra_args: true, ignore_arity: true, &blk)
    end
  end
end

class ActionDispatch::IntegrationTest
  include AuthHelper
end
