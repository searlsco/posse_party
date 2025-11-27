require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  def test_creating_account_seeds_skipped_crossposts_for_existing_posts
    user = users(:user)
    post = posts(:user_post)
    post.update!(crossposts_created_at: Now.time)
    login_as(user)

    post accounts_path, params: {account: {platform_tag: "test", label: "Test Account", manually_create_crossposts: false}}

    new_account = user.accounts.order(:created_at).last
    crosspost = Crosspost.find_by(account: new_account, post:)
    assert_redirected_to accounts_path
    assert_not_nil crosspost
    assert_equal "skipped", crosspost.status
  end

  def test_renew_credentials_redirects_to_provider_url
    user = users(:user)
    login_as(user)
    account = accounts(:user_linkedin_account)

    get renew_credentials_account_path(account)

    assert_response :redirect
    reloaded_account = account.reload
    confirm_redirect = URI.parse(response.location)
    params = Rack::Utils.parse_query(confirm_redirect.query)
    assert_equal "www.linkedin.com", confirm_redirect.host
    assert_equal reloaded_account.credentials["renewal_oauth_state"], params["state"]
    assert_match(/\A[a-f0-9]{32}\z/, reloaded_account.credentials["renewal_oauth_state"])
  end

  def test_renew_credentials_rejects_nonrenewable_account
    user = users(:user)
    login_as(user)
    account = accounts(:user_x_account)

    get renew_credentials_account_path(account)

    assert_redirected_to accounts_path
    assert_equal "Credential renewal unsupported for X (Twitter)", flash[:alert]
  end

  def test_update_clears_disabled_feed_ids_when_param_missing
    user = users(:user)
    login_as(user)
    account = accounts(:user_x_account)
    feed_id = feeds(:user_feed).id
    account.update!(disabled_feed_ids: [feed_id])

    patch account_path(account), params: {account: {label: account.label}}

    assert_redirected_to edit_account_path(account)
    assert_equal [], account.reload.disabled_feed_ids
  end

  def test_update_filters_out_foreign_disabled_feed_ids
    user = users(:user)
    login_as(user)
    account = accounts(:user_x_account)
    own_id = feeds(:user_feed).id
    foreign_id = feeds(:admin_feed).id

    patch account_path(account), params: {account: {label: account.label, disabled_feed_ids: [own_id, foreign_id]}}

    assert_redirected_to edit_account_path(account)
    assert_equal [own_id], account.reload.disabled_feed_ids
  end

  def test_update_with_malformed_disabled_feed_ids_clears_list
    user = users(:user)
    login_as(user)
    account = accounts(:user_x_account)
    own_id = feeds(:user_feed).id
    account.update!(disabled_feed_ids: [own_id])

    # Malformed shape: string instead of array; should default to [] and clear
    patch account_path(account), params: {account: {label: account.label, disabled_feed_ids: "not-an-array"}}

    assert_redirected_to edit_account_path(account)
    assert_equal [], account.reload.disabled_feed_ids
  end

  def test_create_filters_out_foreign_disabled_feed_ids
    user = users(:user)
    login_as(user)
    own_id = feeds(:user_feed).id
    foreign_id = feeds(:admin_feed).id

    post accounts_path, params: {account: {platform_tag: "test", label: "Has Filters", disabled_feed_ids: [own_id, foreign_id]}}

    created = user.accounts.order(:created_at).last
    assert_redirected_to accounts_path
    assert_equal [own_id], created.disabled_feed_ids
  end

  def test_create_with_invalid_credentials_json_returns_error
    user = users(:user)
    login_as(user)

    post accounts_path, params: {account: {platform_tag: "test", label: "Cred JSON", credentials: "{not json"}}

    assert_response :unprocessable_content
    assert_includes flash[:alert], "Invalid JSON"
  end
end
