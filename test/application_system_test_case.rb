require "test_helper"
require_relative "support/test_route_helpers"
require_relative "support/database_helpers"
require_relative "support/auth_mode_helpers"

Capybara.register_driver :my_playwright do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: ENV["PLAYWRIGHT_BROWSER"]&.to_sym || :chromium,
    headless: (false unless ENV["CI"] || ENV["PLAYWRIGHT_HEADLESS"]))
end

Capybara.enable_aria_label = true

Capybara.server = :puma, {Silent: true}

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include TestRouteHelpers
  include DatabaseHelpers
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper
  include AuthModeHelpers

  if ENV["SERIAL"]
    parallelize(workers: 1)
  else
    parallelize(threshold: 0)
  end

  driven_by :my_playwright
  self.use_transactional_tests = true

  def login_as(user)
    set_session_var(:user_id, user.id)
  end

  def find_aria(*nested_labels, **kwargs)
    nested_labels.reduce(page) do |current_scope, label|
      current_scope.find("[aria-label='#{label}']", **kwargs)
    end
  end

  def click_aria(*nested_labels, retries: 3, **kwargs)
    retries.times do
      find_aria(*nested_labels, **kwargs).click
      return
    rescue => e
      raise e if retries == 0 || !e.message.include?("Element is not attached to the DOM")
      sleep 0.1
    end
  end
end
