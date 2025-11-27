require "test_helper"

class CreatesCrosspostForPostTest < ActiveSupport::TestCase
  def test_success_returns_created_crosspost
    # Arrange
    user = users(:admin)
    post_record = posts(:admin_post_without_crossposts)
    account = accounts(:admin_bsky_account)

    # Act
    result = CreatesCrosspostForPost.new.create(user:, post: post_record, account_id: account.id)

    # Assert
    assert result.success?
    crosspost = result.data
    assert_instance_of Crosspost, crosspost
    assert crosspost.persisted?
    assert_equal post_record, crosspost.post
    assert_equal account, crosspost.account
    assert_equal "ready", crosspost.status
  end

  def test_failure_when_account_id_blank
    user = users(:admin)
    post_record = posts(:admin_post_without_crossposts)

    result = CreatesCrosspostForPost.new.create(user:, post: post_record, account_id: nil)

    assert result.failure?
    assert_equal "Select an account", result.error
  end

  def test_failure_when_account_not_found
    user = users(:admin)
    post_record = posts(:admin_post_without_crossposts)

    result = CreatesCrosspostForPost.new.create(user:, post: post_record, account_id: -1)

    assert result.failure?
    assert_equal "Account not found", result.error
  end

  def test_failure_when_account_inactive
    user = users(:admin)
    post_record = posts(:admin_post_without_crossposts)
    account = accounts(:admin_bsky_account)
    account.update!(active: false)

    result = CreatesCrosspostForPost.new.create(user:, post: post_record, account_id: account.id)

    assert result.failure?
    assert_equal "#{account.notification_label} is inactive", result.error
  end

  def test_failure_when_duplicate_crosspost_exists
    user = users(:admin)
    post_record = posts(:admin_post_without_crossposts)
    account = accounts(:admin_bsky_account)
    Crosspost.create!(post: post_record, account: account, status: "ready")

    result = CreatesCrosspostForPost.new.create(user:, post: post_record, account_id: account.id)

    assert result.failure?
    assert_equal "A crosspost already exists for #{account.notification_label}", result.error
  end
end
