class InvitesController < MembersController
  before_action :require_admin
  before_action :set_invite, only: [:destroy, :remind]

  def new
    @invite = Invite.new
  end

  def create
    result = invites_user.invite(
      inviting_user: current_user,
      email: params.require(:invite)[:email]
    )
    @invite = result.invite

    if result.success?
      redirect_to settings_path, notice: invite_flash_messages(result), status: :see_other
    else
      flash.now[:alert] = result.errors
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @invite.destroy!
    redirect_to settings_path, notice: "Invitation revoked.", status: :see_other
  end

  def remind
    result = invites_user.remind(@invite)

    redirect_to settings_path, notice: reminder_flash_messages(result), status: :see_other
  end

  private

  def set_invite
    @invite = current_user.sent_invites.open.includes(:invited_by).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to settings_path, alert: "Invite could not be revoked."
  end

  def invites_user
    @invites_user ||= InvitesUser.new
  end

  def invite_flash_messages(result)
    messages = []

    if result.delivered?
      messages << "Invitation sent to #{result.invite.email}."
    else
      messages << "Invitation created for #{result.invite.email}."
      messages << manual_email_warning(result)
    end

    messages
  end

  def reminder_flash_messages(result)
    if result.delivered?
      "Invitation resent to #{result.invite.email}."
    else
      manual_email_warning(result)
    end
  end

  def manual_email_warning(result)
    email_draft = result.email_draft
    mailto = view_context.mail_to(
      result.invite.email,
      "e-mail them yourself",
      subject: email_draft.subject,
      body: email_draft.body
    )

    "WARNING: because the server is not configured for email delivery, no invitation was sent. Please #{mailto}".html_safe
  end
end
