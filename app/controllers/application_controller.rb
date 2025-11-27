class ApplicationController < ActionController::Base
  before_action :redirect_to_registration_if_no_users

  protected

  def current_user
    if Rails.env.development? && (override_login_id = ENV["LOGGED_IN_USER_ID"].presence)
      @current_user = User.find_by(id: override_login_id) unless @current_user&.id == override_login_id
    elsif session[:user_id].present?
      @current_user ||= User.find_by(id: session[:user_id])
    end
  end

  private

  def redirect_to_registration_if_no_users
    unless User.exists? || in_a_searls_auth_path?
      redirect_to searls_auth.register_path
    end
  end

  def in_a_searls_auth_path?
    request.path.start_with?("/auth")
  end
end
