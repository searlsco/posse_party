require "test_helper"
require_relative "../support/auth_mode_helpers"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  include AuthModeHelpers

  test "manual invite flash renders rich html" do
    with_smtp_unavailable do
      admin = users(:admin)

      login_as(admin)

      post invites_path, params: {invite: {email: "flash-test@example.com"}}
      assert_response :see_other
      follow_redirect!

      assert_select "h2", text: "Account Information"
      assert_select "#flashes a[href^='mailto:']", text: "e-mail them yourself"
      refute_includes response.body, "&lt;a"
    end
  end
end
