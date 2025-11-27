class ApiController < ApplicationController
  skip_before_action :redirect_to_registration_if_no_users
  before_action :authenticate_api_user

  protected

  attr_reader :current_user

  private

  def authenticate_api_user
    auth_header = request.headers["Authorization"]

    if auth_header.blank? || !auth_header.start_with?("Bearer ")
      render json: {error: "Authorization header is required"}, status: :unauthorized
    elsif (@current_user = find_user_by_token(auth_header)).nil?
      render json: {error: "Invalid API key"}, status: :unauthorized
    end
  end

  def find_user_by_token(auth_header)
    token = auth_header.remove(/^Bearer\s+/)
    User.find_by(api_key: token)
  end
end
