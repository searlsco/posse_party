class AccountDeletionsController < MembersController
  def destroy
    user = current_user

    outcome = ConfirmsUserDeletion.new.delete(
      actor: user,
      user: user,
      email_confirmation: params[:dangerous_confirmation]
    )

    if outcome.success?
      deleted_email = user.email
      reset_session
      redirect_to searls_auth.login_path, notice: "Your account (#{deleted_email}) has been deleted."
    else
      redirect_to settings_path, alert: outcome.message
    end
  end
end
