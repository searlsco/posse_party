require "test_helper"

class InviteTest < ActiveSupport::TestCase
  test "accept! marks invite as accepted and clears email" do
    admin = users(:admin)
    recipient = users(:user)
    invite = Invite.create!(email: "recipient@example.com", invited_by: admin)

    travel_to Time.current do
      invite.accept!(recipient)
    end

    assert invite.accepted?
    assert_equal recipient, invite.received_by
    assert_nil invite.email
    assert_not_nil invite.accepted_at
  end

  test "accepted invite requires recipient" do
    admin = users(:admin)
    invite = Invite.new(status: "accepted", invited_by: admin, email: nil)

    refute invite.valid?
    assert_includes invite.errors[:received_by], "must be present when invite is accepted"
  end

  test "invite must be created by admin" do
    non_admin = users(:user)
    invite = Invite.new(email: "someone@example.com", invited_by: non_admin)

    refute invite.valid?
    assert_includes invite.errors[:invited_by], "must be an admin"
  end

  test "cannot invite email that already belongs to a user" do
    admin = users(:admin)
    existing_user = users(:user)

    invite = Invite.new(email: existing_user.email, invited_by: admin)

    refute invite.valid?
    assert_includes invite.errors[:email], "already belongs to an existing user"
  end

  test "cannot create duplicate open invites for same email" do
    admin = users(:admin)

    Invite.create!(email: "duplicate@example.com", invited_by: admin)

    duplicate_invite = Invite.new(email: "duplicate@example.com", invited_by: admin)

    refute duplicate_invite.valid?
    assert_includes duplicate_invite.errors[:email], "has already been taken"
  end
end
