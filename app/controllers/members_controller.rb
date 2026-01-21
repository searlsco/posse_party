class MembersController < ApplicationController
  before_action :require_user

  def self.set_tab(name)
    @__current_tab = name
  end

  def self.tab_name
    @__current_tab
  end

  def tab_name
    self.class.tab_name
  end

  protected

  def require_user
    if current_user.blank?
      redirect_to searls_auth.login_url(
        redirect_path: request.original_fullpath,
        redirect_host: request.host
      ), allow_other_host: true, status: :see_other
    end
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Access denied"
    end
  end
end
