require "application_system_test_case"

class AccountTest < ApplicationSystemTestCase
  def test_complete_account_workflow
    user = users(:user)
    login_as(user)
    click_on "Accounts"

    # CREATE: Add a new Bluesky account
    assert_text "Accounts"
    click_link "Add Account"

    # New account form shows manual crosspost checkboxes in the correct order
    assert_text "Create new account"
    assert_text "Manually create crossposts"
    assert_text "Manually publish crossposts"
    body = page.body
    assert body.index("Manually create crossposts") < body.index("Manually publish crossposts")

    # Fill out basic account info
    fill_in "Label", with: "My Bluesky Account"
    check "Active"
    fill_in "Crosspost cooldown (seconds)", with: "300"
    fill_in "Wait before crossposting (seconds)", with: "60"

    # Select platform and fill credentials
    select "Bluesky", from: "Platform"

    # Wait for credentials fields to load dynamically via Turbo
    assert_text "Credentials for Bluesky"

    # Fill in credentials
    fill_in "Email", with: "test@example.com"
    fill_in "Password", with: "mypassword123"

    click_on "Create Account"
    assert_text "Account created successfully"
    assert_current_path accounts_path

    # Verify account appears in the list
    assert_text "Bluesky"
    assert_text "My Bluesky Account"
    assert_text "Active"

    # Get the account for later use
    @account = Account.find_by(label: "My Bluesky Account")

    # READ/EDIT: Edit the account
    click_link "My Bluesky Account"

    # Verify we're on the edit page with correct data
    assert_field "Label", with: "My Bluesky Account"
    assert_field "Platform", with: "bsky", disabled: true  # Can't change platform
    assert_checked_field "Active"
    assert_field "Crosspost cooldown (seconds)", with: "300"
    assert_field "Wait before crossposting (seconds)", with: "60"
    assert_field "Email", with: "test@example.com"
    assert_field "Password", with: "mypassword123"

    # Edit form shows manual crosspost checkboxes in the correct order
    assert_text "Manually create crossposts"
    assert_text "Manually publish crossposts"
    body = page.body
    assert body.index("Manually create crossposts") < body.index("Manually publish crossposts")

    # UPDATE: Modify some settings
    fill_in "Label", with: "Updated Bluesky Account"
    uncheck "Active"
    check "Manually publish crossposts"
    fill_in "Crosspost cooldown (seconds)", with: "600"
    fill_in "Wait before crossposting (seconds)", with: "120"
    fill_in "Email", with: "updated@example.com"
    fill_in "Password", with: "newpassword456"

    click_on "Save"
    assert_text "Account updated successfully"
    assert_current_path edit_account_path(@account)

    # Navigate back to the accounts list to verify changes
    visit accounts_path
    assert_text "Updated Bluesky Account"
    assert_text "Disabled"  # Should show disabled now

    # Go back to edit to verify ALL changes persisted
    click_link "Updated Bluesky Account"
    assert_field "Label", with: "Updated Bluesky Account"
    assert_field "Platform", with: "bsky", disabled: true  # Still can't change platform
    assert_unchecked_field "Active"
    assert_checked_field "Manually publish crossposts"
    assert_field "Crosspost cooldown (seconds)", with: "600"
    assert_field "Wait before crossposting (seconds)", with: "120"
    assert_field "Email", with: "updated@example.com"
    assert_field "Password", with: "newpassword456"

    # Test platform-specific credential fields and Turbo Frame switching
    # Open new account form directly (link nav covered earlier)
    visit new_account_path

    # Test X (Twitter) credentials
    select "X (Twitter)", from: "Platform"
    assert_text "Credentials for X"
    assert_field "Api key"
    assert_field "Access token"
    assert_field "Api key secret"
    assert_field "Access token secret"

    # Switch to LinkedIn - should show different fields
    select "LinkedIn", from: "Platform"
    assert_text "Credentials for LinkedIn"
    assert_field "Client"
    assert_field "Access token"
    assert_field "Client secret"
    assert_field "Person urn"
    # Verify X fields are gone
    assert_no_field "Api key"
    assert_no_field "Api key secret"
    # Switch back to X to prove it works both ways
    select "X (Twitter)", from: "Platform"
    assert_text "Credentials for X"
    assert_field "Api key"
    assert_field "Api key secret"

    # Go back and test delete (open edit directly)
    visit edit_account_path(@account)

    # Verify the delete button appears
    assert_text "Manage this account"
    assert_text "Delete Account"

    # Test delete with confirmation
    accept_confirm("Are you sure you want to delete this account? This will permanently delete the account and all 1 associated crosspost(s). This action cannot be undone.") do
      click_on "Delete Account"
    end

    assert_text "Account deleted successfully."
    assert_current_path accounts_path
    assert_no_text "Updated Bluesky Account"
  end
end
