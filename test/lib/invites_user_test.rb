require "test_helper"

class InvitesUserTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @admin = users(:admin)
    ActionMailer::Base.deliveries.clear
  end

  teardown do
    ActionMailer::Base.deliveries.clear
    Rails.configuration.action_mailer.delivery_method = :test
  end

  test "creates invite and delivers email when capability allows" do
    result = nil

    assert_difference -> { Invite.count }, +1 do
      perform_enqueued_jobs do
        result = InvitesUser.new.invite(inviting_user: @admin, email: "new@example.com")
      end
    end

    assert result.success?
    assert result.delivered?
    assert_equal "new@example.com", result.invite.email
    assert_equal 1, ActionMailer::Base.deliveries.size

    email_draft = result.email_draft
    delivered = ActionMailer::Base.deliveries.last
    assert_equal ["new@example.com"], delivered.to
    body = delivered.body.decoded
    assert_includes body, "#{@admin.email} has invited you"
    assert_includes body, email_draft.register_url
    assert_equal expected_register_url(email: "new@example.com"), email_draft.register_url
  end

  test "creates invite without delivering email when capability disabled" do
    result = nil

    fake_capability = Mocktail.of_next(DeterminesEmailCapability)
    stubs { fake_capability.determine }.with { false }

    assert_difference -> { Invite.count }, +1 do
      perform_enqueued_jobs do
        result = InvitesUser.new.invite(inviting_user: @admin, email: "offline@example.com")
      end
    end

    refute result.delivered?
    assert result.success?
    assert_equal 0, ActionMailer::Base.deliveries.size
    assert_includes result.email_draft.body, @admin.email
    assert_equal expected_register_url(email: "offline@example.com"), result.email_draft.register_url
  end

  test "remind resends invite when capability allows" do
    invite = nil
    perform_enqueued_jobs do
      invite = InvitesUser.new.invite(inviting_user: @admin, email: "remind@example.com").invite
    end

    ActionMailer::Base.deliveries.clear

    result = nil
    perform_enqueued_jobs do
      result = InvitesUser.new.remind(invite)
    end

    assert result.delivered?
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal ["remind@example.com"], ActionMailer::Base.deliveries.last.to
    assert_equal expected_register_url(email: "remind@example.com"), result.email_draft.register_url
  end

  private

  def expected_register_url(email:)
    Searls::Auth::Engine.routes.url_helpers.register_url(**Rails.application.routes.default_url_options, email:)
  end
end
