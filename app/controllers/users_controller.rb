class UsersController < MembersController
  before_action :require_admin

  def destroy
    user = User.find(params[:id])

    outcome = ConfirmsUserDeletion.new.delete(
      actor: current_user,
      user: user,
      email_confirmation: params[:dangerous_confirmation]
    )

    respond_to do |format|
      format.turbo_stream { render_user_management_stream(outcome) }
      format.html { redirect_to settings_path, outcome.flash_type => outcome.message }
    end
  end

  def update
    outcome = UpdatesUserRole.new.update(
      actor: current_user,
      user: (user = User.find(params[:id])),
      admin_demotion: (admin_demotion = !ActiveModel::Type::Boolean.new.cast(params[:admin])),
      confirmation: params[:dangerous_confirmation]
    )

    if outcome.success? && admin_demotion && current_user.id == user.id
      redirect_to settings_path, outcome.flash_type => outcome.message
    else
      respond_to do |format|
        format.turbo_stream { render_user_management_stream(outcome) }
        format.html { redirect_to settings_path, outcome.flash_type => outcome.message }
      end
    end
  end

  private

  def render_user_management_stream(outcome)
    all_users = User.order(:email)
    managed_users = all_users.reject { |u| u.id == current_user.id }
    admin_users = all_users.select(&:admin?)
    sole_admin_id = admin_users.one? ? admin_users.first.id : nil
    total_user_count = all_users.size

    flash.now[outcome.flash_type] = outcome.message

    render turbo_stream: [
      turbo_stream.update("flashes", partial: "shared/flashes"),
      turbo_stream.replace("users_list", partial: "settings/user_list", locals: {
        users: managed_users,
        current_user: current_user,
        sole_admin_id: sole_admin_id,
        total_user_count: total_user_count
      }),
      turbo_stream.replace("danger_zone", partial: "settings/danger_zone", locals: {
        user: current_user
      })
    ]
  end
end
