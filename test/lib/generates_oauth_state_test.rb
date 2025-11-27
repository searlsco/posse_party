require "test_helper"

class GeneratesOauthStateTest < ActiveSupport::TestCase
  def test_generate_updates_credentials_even_with_stale_disabled_feed_ids
    account = accounts(:user_youtube_account)
    # Simulate historical bad data: a feed id from another user persisted on the account
    foreign_feed_id = feeds(:admin_feed).id
    account.update_columns(disabled_feed_ids: [foreign_feed_id])

    state = nil
    assert_nothing_raised do
      state = GeneratesOauthState.new.generate(account)
    end

    assert_match(/\A[0-9a-f]{32}\z/, state)
    assert_equal state, account.reload.credentials["renewal_oauth_state"]
  end
end
