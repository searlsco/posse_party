require "test_helper"

class Notifications::CreatesNotificationTest < ActiveSupport::TestCase
  def setup
    @subject = Notifications::CreatesNotification.new
    @user = User.create!(
      email: "u@example.com",
      api_key: SecureRandom.hex(32),
      password: "Password!1",
      password_confirmation: "Password!1"
    )
  end

  test "coerces severity, normalizes refs, and creates notification" do
    assert_difference -> { Notification.count }, +1 do
      @subject.create!(
        user: @user,
        title: "T",
        severity: :unknown,
        text: "X",
        refs: [{"model" => :Post, "id" => "12"}],
        badge: true
      )
    end
    m = Notification.last
    assert_equal "info", m.severity
    assert_equal [{"model" => "Post", "id" => 12}], m.refs
    assert_equal true, m.badge
  end
end
