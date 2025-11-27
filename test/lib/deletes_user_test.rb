require "test_helper"

class DeletesUserTest < ActiveSupport::TestCase
  def setup
    @subject = DeletesUser.new
    @admin = users(:admin)
    @user = users(:user)
  end

  def test_prevents_deleting_last_admin_when_others_exist
    outcome = @subject.delete(actor: @admin, user: @admin)

    assert outcome.failure?
    assert_equal "At least one administrator must remain so long as any non-admin users exist.", outcome.message
    assert User.exists?(@admin.id)
  end

  def test_allows_admin_deletion_when_only_user
    Invite.delete_all
    User.includes(
      accounts: :crossposts,
      feeds: {posts: :crossposts}
    ).where.not(id: @admin.id).find_each(&:destroy!)

    outcome = @subject.delete(actor: @admin, user: @admin)

    assert outcome.success?
    assert_equal "User deleted successfully.", outcome.message
    refute User.exists?(@admin.id)
  end

  def test_deletes_non_admin_user
    outcome = @subject.delete(actor: @admin, user: @user)

    assert outcome.success?
    assert_equal "User deleted successfully.", outcome.message
    refute User.exists?(@user.id)
  end

  def test_deletes_fresh_non_admin_user
    new_user = New.create(User, email: "deleteme@example.com")

    outcome = @subject.delete(actor: @admin, user: new_user)

    assert outcome.success?
    assert_equal "User deleted successfully.", outcome.message
    refute User.exists?(new_user.id)
  end

  def test_non_admin_cannot_delete_other_user
    outcome = @subject.delete(actor: @user, user: @admin)

    assert outcome.failure?
    assert_equal "Only administrators can delete other users.", outcome.message
    assert User.exists?(@admin.id)
  end

  def test_non_admin_can_delete_self
    outcome = @subject.delete(actor: @user, user: @user)

    assert outcome.success?
    assert_equal "User deleted successfully.", outcome.message
    refute User.exists?(@user.id)
  end

  def test_deleting_self_removes_pending_invites
    # Arrange: ensure admin can delete self by adding another admin
    New.create(User, email: "extra_admin@example.com", admin: true)

    # Admin creates a pending invite
    email = "pending_to_remove@example.com"
    result = InvitesUser.new.invite(inviting_user: @admin, email: email)
    assert result.success?
    assert Invite.open.for_email(email).exists?

    # Act: admin deletes self
    outcome = @subject.delete(actor: @admin, user: @admin)

    # Assert: user deleted and their pending invite removed within the same transaction
    assert outcome.success?
    refute User.exists?(@admin.id)
    refute Invite.open.for_email(email).exists?
  end
end
