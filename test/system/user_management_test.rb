require "application_system_test_case"

class UserManagementTest < ApplicationSystemTestCase
  def setup
    @admin_user = users(:admin)
    @regular_user = users(:user)
  end

  private

  def user_row_for(email)
    find("[data-active-user-email='#{email}']")
  end

  def invite_row_for(email)
    find("[data-invite-email='#{email}']")
  end

  test "comprehensive user management and invite workflow" do
    # Admin views settings
    login_as(@admin_user)
    visit settings_path

    assert_text "Settings"
    assert_text "Users"
    assert_text "Invite User"
    assert_selector "a[href='#{status_path}']", text: "System Status"
    assert_selector "a[href='/jobs']", text: "Job Status"
    assert_text @regular_user.email
    assert_field "Current password"
    assert_field "New password", type: :password

    original_password = "AdminPassword!1"
    new_password = "AdminPassword!2"

    fill_in "Current password", with: "TotallyWrong!"
    fill_in "New password", with: new_password
    fill_in "Confirm new password", with: new_password
    click_button "Update Password"

    assert_text "That current password doesn't match our records."
    assert @admin_user.reload.authenticate(original_password)

    fill_in "Current password", with: original_password
    fill_in "New password", with: new_password
    fill_in "Confirm new password", with: new_password
    click_button "Update Password"

    assert_text "Settings updated."
    @admin_user = @admin_user.reload
    assert @admin_user.authenticate(new_password)

    # Admin invites a new user
    click_link "Invite User"
    assert_current_path new_invite_path
    assert_text "Invite User"

    # Fill in email
    unique_email = "invited_#{Time.current.to_i}@example.com"
    fill_in "Email", with: unique_email
    click_button "Invite User"

    assert_current_path settings_path
    assert_text "Invitation sent to #{unique_email}."
    assert_text unique_email
    assert Invite.open.for_email(unique_email).exists?
    assert_nil User.find_by(email: unique_email)

    # Verify the pending invite row appears with the correct email and actions
    within invite_row_for(unique_email) do
      assert_selector "span", text: unique_email
      assert_selector "button", text: "Revoke"
    end

    # Invite and then revoke another invite (merge from InviteRegistrationFlowTest)
    click_link "Invite User"
    revoke_email = "revoke_#{Time.current.to_i}@example.com"
    fill_in "Email", with: revoke_email
    click_button "Invite User"
    assert_text "Invitation sent to #{revoke_email}."
    within invite_row_for(revoke_email) do
      accept_confirm do
        click_button "Revoke"
      end
    end
    assert_text "Invitation revoked."
    assert_no_text revoke_email

    active_user_emails = all("[data-active-user-email]").map { |row| row["data-active-user-email"] }
    assert_equal active_user_emails.sort, active_user_emails

    # Test API key regeneration
    original_api_key = @admin_user.reload.api_key
    assert_selector "code", text: original_api_key

    accept_confirm do
      click_button "Regenerate"
    end

    assert_text "API key regenerated successfully"
    new_api_key = @admin_user.reload.api_key
    assert_not_equal original_api_key, new_api_key
    assert_selector "code", text: new_api_key

    danger_zone_container = find(:xpath, "//h2[normalize-space()='Danger Zone']/ancestor::div[contains(@class,'rounded-xl')]")
    within danger_zone_container do
      assert_selector "button", text: "Delete Account"
    end
  end

  test "non-admin restrictions and deletion by admin" do
    # Log in as regular user
    login_as(@regular_user)
    visit settings_path

    # Non-admin cannot see user management
    assert_text "Settings"
    assert_no_text "Users"
    assert_no_text "Invite User"
    assert_no_selector "a[href='#{status_path}']", text: "System Status"
    assert_no_selector "a[href='/jobs']", text: "Job Status"
    assert_selector "code", text: @regular_user.api_key

    danger_zone_container = find(:xpath, "//h2[normalize-space()='Danger Zone']/ancestor::div[contains(@class,'rounded-xl')]")
    within danger_zone_container do
      click_button "Delete Account"
    end
    within find("dialog[open]") do
      fill_in "Type #{@regular_user.email} to confirm", with: "wrong@example.com"
      click_button "Delete account"
    end
    assert_text "Email confirmation must match #{@regular_user.email}."
    assert_current_path settings_path

    # Non-admin cannot access invite page - redirects to root
    visit new_invite_path
    assert_current_path root_path

    # Admin deletes the regular user
    login_as(@admin_user)
    visit settings_path
    assert_text @regular_user.email

    within user_row_for(@regular_user.email) do
      click_button "Delete"
    end
    within find("dialog[open]") do
      fill_in "Type #{@regular_user.email} to confirm", with: @regular_user.email
      click_button "Delete user"
    end

    assert_text "User deleted successfully"
    assert_no_text @regular_user.email
    assert_nil User.find_by(id: @regular_user.id)

    click_link "Log out"
    assert_text "You've been logged out"
    visit settings_path
    assert_equal searls_auth.login_path, current_path
    assert_includes current_url, "?redirect_path=%2Fsettings"
  end
end
