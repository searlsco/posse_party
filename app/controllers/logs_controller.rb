class LogsController < MembersController
  include GearedPagination::Controller

  set_tab :logs

  NOTIFICATIONS_PER_PAGE = 30

  def index
    @query = params[:q]&.strip

    scope = current_user.notifications.order(created_at: :desc)
    scope = Notification.search(@query).merge(scope)
    @notifications = set_page_and_extract_portion_from scope, per_page: NOTIFICATIONS_PER_PAGE

    respond_to do |format|
      format.html
      format.turbo_stream if turbo_frame_request?
    end
  end

  def show
    @notification = current_user.notifications.find(params[:id])
    @notification.update_column(:seen_at, Now.time) if @notification.seen_at.nil?
    @ref_records = Notifications::PreloadsRefs.new.preload(@notification.refs)
  end

  def destroy
    notification = current_user.notifications.find(params[:id])
    notification.destroy
    redirect_to logs_path, notice: "Log deleted"
  end

  def destroy_all
    current_user.notifications.delete_all
    redirect_to logs_path, notice: "All logs deleted"
  end

  def mark_all_seen
    current_user.notifications.where(seen_at: nil).update_all(seen_at: Now.time)
    redirect_to logs_path, notice: "All logs marked as seen"
  end
end
