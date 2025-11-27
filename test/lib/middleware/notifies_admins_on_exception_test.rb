require "test_helper"

class NotifiesAdminsOnExceptionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def app_that_raises
    ->(_env) { raise StandardError, "Boom!" }
  end

  def test_notifies_admins_when_exception_bubbles_as_500
    middleware = Middleware::NotifiesAdminsOnException.new(app_that_raises)

    perform_enqueued_jobs do
      assert_raises(StandardError) do
        middleware.call(Rack::MockRequest.env_for("/oops"))
      end
    end

    assert_operator ActionMailer::Base.deliveries.size, :>=, 1
    mail = ActionMailer::Base.deliveries.last
    assert_equal "POSSE Party 500 Error: Boom!", mail.subject
    assert_includes mail.subject, "Boom!"
  end
end
