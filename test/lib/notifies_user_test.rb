require "test_helper"

class NotifiesUserTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  FakeExtraction = Struct.new(:text, :refs, keyword_init: true)

  def setup
    @user = User.create!(
      email: "x@example.com",
      api_key: SecureRandom.hex(32),
      password: "Password!1",
      password_confirmation: "Password!1"
    )
    @subject = NotifiesUser.new
  end

  test "sends email and creates notification" do
    perform_enqueued_jobs do
      @subject.notify(
        mail: NotificationMailer,
        method: :notify,
        params: {subject: "S", message: "B"},
        user: @user,
        title: "T",
        severity: "warn",
        refs: [],
        badge: true
      )
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal 1, Notification.count
    m = Notification.last
    assert_equal @user.id, m.user_id
    assert_equal "T", m.title
    assert_equal "warn", m.severity
    assert_includes m.text, "B"
    assert_equal [], m.refs
    assert_equal true, m.badge
  end

  test "mail:true defaults to generic mailer. sends email and creates notification" do
    perform_enqueued_jobs do
      @subject.notify(
        mail: true,
        user: @user,
        title: "T",
        severity: "warn",
        text: "B",
        refs: [],
        badge: true
      )
    end

    assert_equal 1, Notification.count
    n = Notification.last
    assert_equal @user.id, n.user_id
    assert_equal "T", n.title
    assert_equal "warn", n.severity
    assert_equal "B", n.text
    assert_equal [], n.refs
    assert_equal true, n.badge
    assert_equal 1, ActionMailer::Base.deliveries.size
    m = ActionMailer::Base.deliveries.last
    assert_equal "T", m.subject
    assert_match Regexp.new(<<~'RE'.strip % {id: n.id}), m.body.to_s
      Notification sent from POSSE Party at \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z:

      B

      See notification at: http://posseparty.com/logs/%{id}
    RE
  end

  test "either mailer or text must be provided" do
    e = assert_raises do
      @subject.notify(
        user: @user,
        title: "T",
        severity: "warn",
        refs: [],
        badge: true
      )
    end
    assert_equal e.message, "Either :text or :mail and :method MUST be provided"
  end

  test "skips email delivery when capability disabled" do
    creates_notification = Mocktail.of_next(Notifications::CreatesNotification)
    extracts_text_from_simulated_email = Mocktail.of_next(ExtractsTextFromSimulatedEmail)
    determines_email_capability = Mocktail.of_next(DeterminesEmailCapability)
    stubs { extracts_text_from_simulated_email.extract(mail: NotificationMailer, method: :notify, params: "params") }.with { FakeExtraction.new(text: "extractedtext", refs: ["eref"]) }
    stubs { determines_email_capability.determine }.with { false }
    subject = NotifiesUser.new

    perform_enqueued_jobs do
      subject.notify(
        mail: NotificationMailer,
        method: :notify,
        params: "params",
        user: @user,
        title: "T",
        severity: "warn",
        text: "B",
        refs: [],
        badge: true
      )
    end

    assert_empty ActionMailer::Base.deliveries
    verify { creates_notification.create!(user: @user, title: "T", text: "extractedtext", severity: "warn", refs: ["eref"], badge: true) }
  end
end
