class AdminController < MembersController
  before_action :require_admin

  protected

  def require_admin
    if !current_user&.admin?
      redirect_to searls_auth.login_url(
        redirect_path: request.original_fullpath,
        redirect_host: request.host
      ), allow_other_host: true, status: :see_other
    end
  end
end
