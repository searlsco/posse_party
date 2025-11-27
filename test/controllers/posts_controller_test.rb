require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  def test_create_crosspost_redirects_to_new_crosspost
    user = users(:admin)
    login_as(user)

    post_record = posts(:admin_post_without_crossposts)
    account = accounts(:admin_bsky_account)

    post create_crosspost_post_path(post_record), params: {crosspost: {account_id: account.id}}

    created = Crosspost.find_by!(post: post_record, account: account)
    assert_redirected_to crosspost_path(created)
    assert_equal "Created crosspost for #{account.notification_label}", flash[:notice]
  end
end
