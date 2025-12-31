require "test_helper"

class RenewsInstagramAccessTokenTest < ActiveSupport::TestCase
  def test_updates_only_access_token_and_preserves_other_credentials
    fake_time!("2025-12-30 12:00:00 UTC", freeze: true) do |now|
      account = New.create(Account,
        platform_tag: "instagram",
        label: "@testman",
        credentials: {
          "app_id" => "SOME_APP_ID",
          "app_secret" => "SOME_APP_SECRET",
          "user_id" => "SOME_USER_ID",
          "access_token" => "OLD_ACCESS_TOKEN"
        },
        credentials_renewed_at: nil)
      calls_instagram_api = Mocktail.of_next(Platforms::Instagram::CallsInstagramApi)
      stubs {
        calls_instagram_api.call(method: :get, path: "refresh_access_token", query: {grant_type: "ig_refresh_token", access_token: "OLD_ACCESS_TOKEN"})
      }.with {
        Platforms::Instagram::CallsInstagramApi::Result.new(success?: true, data: {access_token: "NEW_ACCESS_TOKEN"})
      }

      outcome = Platforms::Instagram::RenewsInstagramAccessToken.new.renew!(account)

      assert outcome.success?
      assert_equal({
        "app_id" => "SOME_APP_ID",
        "app_secret" => "SOME_APP_SECRET",
        "user_id" => "SOME_USER_ID",
        "access_token" => "NEW_ACCESS_TOKEN"
      }, account.reload.credentials)
      assert_equal now, account.credentials_renewed_at
    end
  end
end
