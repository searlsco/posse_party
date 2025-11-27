require "test_helper"

class ConfirmsUserDeletionTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin)
    @user = users(:user)
    @subject = ConfirmsUserDeletion.new
  end

  test "requires email confirmation" do
    outcome = @subject.delete(actor: @user, user: @user, email_confirmation: " ")

    assert outcome.failure?
    assert_equal "Please enter #{@user.email} to confirm deletion.", outcome.message
  end

  test "rejects mismatched email" do
    outcome = @subject.delete(actor: @user, user: @user, email_confirmation: "not-it@example.com")

    assert outcome.failure?
    assert_equal "Email confirmation must match #{@user.email}.", outcome.message
  end

  test "deletes user when confirmation matches" do
    deletable = New.create(User, email: "deleteme@example.com")

    outcome = @subject.delete(actor: @admin, user: deletable, email_confirmation: deletable.email)

    assert outcome.success?
    assert_equal "User deleted successfully.", outcome.message
    refute User.exists?(deletable.id)
  end

  test "non admin cannot delete others" do
    other_user = New.create(User, email: "other@example.com")

    outcome = @subject.delete(actor: @user, user: other_user, email_confirmation: other_user.email)

    assert outcome.failure?
    assert_equal "Only administrators can delete other users.", outcome.message
    assert User.exists?(other_user.id)
  end
end
