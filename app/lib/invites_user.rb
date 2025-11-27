class InvitesUser
  Result = Struct.new(:invite, :errors, :email_draft, :delivered?, :success?, keyword_init: true)

  def initialize
    @email_capability = DeterminesEmailCapability.new
    @mailer = InviteMailer
    @email_builder = BuildsInviteEmail.new
  end

  def invite(inviting_user:, email:)
    invite = Invite.new(email:, invited_by: inviting_user)

    if invite.save
      email_draft = @email_builder.build(invite)
      Result.new(invite:, errors: [], email_draft:, delivered?: deliver(invite), success?: true)
    else
      Result.new(invite:, errors: invite.errors.full_messages, email_draft: nil, delivered?: false, success?: false)
    end
  end

  def remind(invite)
    email_draft = @email_builder.build(invite)
    Result.new(invite:, errors: [], email_draft:, delivered?: deliver(invite), success?: true)
  end

  private

  def deliver(invite)
    return false unless email_capability_enabled?

    @mailer.with(invite: invite).invite.deliver_later
    true
  end

  def email_capability_enabled?
    @email_capability.determine
  end
end
