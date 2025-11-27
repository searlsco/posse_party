require "test_helper"

class NotifiesAdminsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @user = users(:admin)
    @subject = NotifiesAdmins.new
  end

  test "sends email and creates notifications for admins" do
    perform_enqueued_jobs do
      @subject.call(subject: "S", body: "B", severity: "warn", badge: true)
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal 1, Notification.count
    m = Notification.last
    assert_equal @user.id, m.user_id
    assert_equal "S", m.title
    assert_equal "warn", m.severity
    assert_includes m.text, "B"
    assert_equal true, m.badge
  end
end
