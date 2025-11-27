class SettingsController < MembersController
  set_tab :settings
  PERMITTED_PARAMS = [].freeze

  def show
    @user = current_user
    @email_delivery_enabled = DeterminesEmailCapability.new.determine

    if @user.admin?
      @status_verification = ChecksSystemStatus.new.check(cache: true)
      ordered_invites = @user
        .sent_invites
        .includes(:invited_by, :received_by)
        .order(created_at: :desc)
      @open_invites = ordered_invites.select(&:open?)
      all_users = User.order(:email)
      @managed_users = all_users.reject { |u| u.id == @user.id }
    end
  end

  def update
    @user = current_user

    user_params = params.require(:user).permit(PERMITTED_PARAMS)

    if @user.update(user_params)
      redirect_to settings_path, notice: "Settings updated successfully"
    else
      flash[:alert] = @user.errors.full_messages.join(", ")
      render :show, status: :unprocessable_content
    end
  end

  def regenerate_api_key
    outcome = RegeneratesApiKey.new.regenerate(current_user)

    if outcome.success?
      redirect_to settings_path, notice: outcome.message
    else
      redirect_to settings_path, alert: outcome.message
    end
  end

  def api
    @user = current_user
  end
end
