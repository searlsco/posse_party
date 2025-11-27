require "test_helper"

class UpdatesUserRoleTest < ActiveSupport::TestCase
  def setup
    @subject = UpdatesUserRole.new
    @admin = users(:admin)
    @user = users(:user)
  end

  def test_admin_can_promote_standard_user
    outcome = @subject.update(actor: @admin, user: @user, admin_demotion: false)

    assert outcome.success?
    assert_equal "#{@user.email} is now an administrator.", outcome.message
    assert @user.reload.admin?
  end

  def test_admin_can_demote_another_admin_when_others_remain
    extra_admin = New.create(User, email: "extra@example.com", admin: true)

    outcome = @subject.update(actor: @admin, user: extra_admin, admin_demotion: true)

    assert outcome.success?
    assert_equal "#{extra_admin.email} is now a standard user.", outcome.message
    refute extra_admin.reload.admin?
  end

  def test_prevents_demotion_of_last_admin_when_other_users_exist
    outcome = @subject.update(actor: @admin, user: @admin, admin_demotion: true, confirmation: @admin.email)

    assert outcome.failure?
    assert_equal "At least one user must be an admin", outcome.message
    assert @admin.reload.admin?
  end

  def test_allows_demotion_of_last_admin_when_only_user
    Invite.delete_all
    User.where.not(id: @admin.id).delete_all

    outcome = @subject.update(actor: @admin, user: @admin, admin_demotion: true, confirmation: @admin.email)

    assert outcome.success?
    assert_equal "#{@admin.email} is now a standard user.", outcome.message
    refute @admin.reload.admin?
  end

  def test_non_admin_cannot_update_roles
    outcome = @subject.update(actor: @user, user: @admin, admin_demotion: true)

    assert outcome.failure?
    assert_equal "Only administrators can modify user roles.", outcome.message
    assert @admin.reload.admin?
  end

  def test_returns_success_when_role_is_unchanged
    outcome = @subject.update(actor: @admin, user: @admin, admin_demotion: false)

    assert outcome.success?
    assert_equal "#{@admin.email} is now an administrator.", outcome.message
  end

  def test_self_demotion_requires_confirmation
    outcome = @subject.update(actor: @admin, user: @admin, admin_demotion: true, confirmation: "")

    assert outcome.failure?
    assert_equal "Please enter #{@admin.email} to confirm demotion.", outcome.message
    assert @admin.reload.admin?
  end

  def test_self_demotion_requires_matching_confirmation
    outcome = @subject.update(actor: @admin, user: @admin, admin_demotion: true, confirmation: "wrong@example.com")

    assert outcome.failure?
    assert_equal "Email confirmation must match #{@admin.email}.", outcome.message
    assert @admin.reload.admin?
  end
end
