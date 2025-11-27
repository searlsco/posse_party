class InviteMailer < ApplicationMailer
  def invite
    @invite = params[:invite]
    @email_draft = BuildsInviteEmail.new.build(@invite)

    mail(to: @invite.email, subject: @email_draft.subject)
  end
end
