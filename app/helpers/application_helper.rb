module ApplicationHelper
  def flash_messages?
    flash[:notice].present? || flash[:alert].present?
  end

  def current_user
    @current_user
  end
end
