require "test_helper"

class CredentialRenewalsControllerTest < ActionDispatch::IntegrationTest
  def test_linkedin_oauth_callback_success_does_not_error_and_notifies
    renews_linked_in_token = Mocktail.of_next(Platforms::Linkedin::RenewsLinkedInTokenFromOAuthCallback)
    user = users(:user)
    account = accounts(:user_linkedin_account)
    stubs { renews_linked_in_token.renew(code: "abc", state: "STATE123") }.with { Platforms::Linkedin::RenewsLinkedInTokenFromOAuthCallback::Result.new(success?: true, account: account) }
    login_as(user)

    get credential_renewals_linkedin_path(code: "abc", state: "STATE123")

    assert_redirected_to edit_account_path(account)
    assert_equal "LinkedIn credentials successfully renewed!", flash[:notice]
  end

  def test_linkedin_oauth_callback_success_when_logged_out_notifies_account_owner
    renews_linked_in_token = Mocktail.of_next(Platforms::Linkedin::RenewsLinkedInTokenFromOAuthCallback)
    account = accounts(:user_linkedin_account)
    new_access_token = "new-linkedin-token"
    stubs { renews_linked_in_token.renew(code: "abc", state: "STATE123") }.with {
      account.update!(credentials: account.credentials.merge("access_token" => new_access_token))
      Platforms::Linkedin::RenewsLinkedInTokenFromOAuthCallback::Result.new(success?: true, account: account)
    }

    assert_changes -> { Notification.count }, +1 do
      get credential_renewals_linkedin_path(code: "abc", state: "STATE123")
    end

    assert_redirected_to edit_account_path(account)
    assert_equal "LinkedIn credentials successfully renewed!", flash[:notice]
    assert_equal new_access_token, account.reload.credentials["access_token"]
    assert_equal account.user, Notification.last.user
  end

  def test_linkedin_oauth_callback_failure_invalid_state_redirects_and_sets_alert
    renews_linked_in_token = Mocktail.of_next(Platforms::Linkedin::RenewsLinkedInTokenFromOAuthCallback)
    user = users(:user)
    stubs { renews_linked_in_token.renew(code: "abc", state: "BAD") }.with { Platforms::Linkedin::RenewsLinkedInTokenFromOAuthCallback::Result.new(success?: false, message: "Invalid state parameter") }
    login_as(user)

    get credential_renewals_linkedin_path(code: "abc", state: "BAD")

    assert_redirected_to accounts_path
    assert_equal "LinkedIn credential renewal failed. Please try again.", flash[:alert]
  end

  def test_linkedin_oauth_callback_failure_invalid_state_when_logged_out_skips_notify
    renews_linked_in_token = Mocktail.of_next(Platforms::Linkedin::RenewsLinkedInTokenFromOAuthCallback)
    stubs { renews_linked_in_token.renew(code: "abc", state: "BAD") }.with { Platforms::Linkedin::RenewsLinkedInTokenFromOAuthCallback::Result.new(success?: false, message: "Invalid state parameter") }

    assert_no_changes -> { Notification.count } do
      get credential_renewals_linkedin_path(code: "abc", state: "BAD")
    end

    assert_redirected_to accounts_path
    assert_equal "LinkedIn credential renewal failed. Please try again.", flash[:alert]
  end

  def test_youtube_oauth_callback_success_redirects_and_notifies
    exchanges_youtube_token = Mocktail.of_next(Platforms::Youtube::ExchangesYoutubeToken)
    user = users(:user)
    account = accounts(:user_youtube_account)
    stubs { exchanges_youtube_token.exchange("abc", "STATE123") }.with { Platforms::Youtube::ExchangesYoutubeToken::Result.new(success?: true, account: account) }
    login_as(user)

    get credential_renewals_youtube_path(code: "abc", state: "STATE123")

    assert_redirected_to edit_account_path(account)
    assert_equal "YouTube credentials successfully renewed!", flash[:notice]
  end

  def test_youtube_oauth_callback_success_when_logged_out_notifies_account_owner
    exchanges_youtube_token = Mocktail.of_next(Platforms::Youtube::ExchangesYoutubeToken)
    account = accounts(:user_youtube_account)
    new_access_token = "new-youtube-access-token"
    new_refresh_token = "new-youtube-refresh-token"
    stubs { exchanges_youtube_token.exchange("abc", "STATE123") }.with {
      account.update!(credentials: account.credentials.merge(
        "access_token" => new_access_token,
        "refresh_token" => new_refresh_token
      ))
      Platforms::Youtube::ExchangesYoutubeToken::Result.new(success?: true, account: account)
    }

    assert_changes -> { Notification.count }, +1 do
      get credential_renewals_youtube_path(code: "abc", state: "STATE123")
    end

    assert_redirected_to edit_account_path(account)
    assert_equal "YouTube credentials successfully renewed!", flash[:notice]
    assert_equal new_access_token, account.reload.credentials["access_token"]
    assert_equal new_refresh_token, account.credentials["refresh_token"]
    assert_equal account.user, Notification.last.user
  end

  def test_youtube_oauth_callback_failure_invalid_state_redirects_and_sets_alert
    exchanges_youtube_token = Mocktail.of_next(Platforms::Youtube::ExchangesYoutubeToken)
    user = users(:user)
    stubs { exchanges_youtube_token.exchange("abc", "BAD") }.with { Platforms::Youtube::ExchangesYoutubeToken::Result.new(success?: false, message: "Invalid state parameter") }
    login_as(user)

    get credential_renewals_youtube_path(code: "abc", state: "BAD")

    assert_redirected_to accounts_path
    assert_equal "YouTube credential renewal failed. Please try again.", flash[:alert]
  end
end
