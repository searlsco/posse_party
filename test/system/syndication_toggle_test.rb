require "application_system_test_case"

class SyndicationToggleTest < ApplicationSystemTestCase
  def test_toggle_automatic_syndication_from_accounts_index
    user = users(:user)
    user.update!(allow_automatic_syndication: true)
    login_as(user)

    visit accounts_path
    assert_text "Accounts"

    assert_checked_field "Enable automated syndication"

    uncheck "Enable automated syndication"
    assert_text "Automatic syndication was successfully disabled."

    check "Enable automated syndication"
    assert_text "Automatic syndication was successfully enabled."

    uncheck "Enable automated syndication"
    assert_text "Automatic syndication was successfully disabled."

    visit current_path
    assert_unchecked_field "Enable automated syndication"
  end
end
