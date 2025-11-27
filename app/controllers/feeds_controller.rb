class FeedsController < MembersController
  include ActionView::Helpers::TextHelper

  set_tab :feeds
  PERMITTED_PARAMS = [:label, :url, :active, :automatically_create_crossposts].freeze

  def index
    @feeds = current_user.feeds
  end

  def new
    @feed = current_user.feeds.build
  end

  def create
    @feed = current_user.feeds.build(params.require(:feed).permit(PERMITTED_PARAMS))

    if @feed.save
      perform_check_with_counts!(@feed, :create)
      redirect_to feeds_path
    else
      flash[:alert] = @feed.errors.full_messages.join(", ")
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @feed = current_user.feeds.find(params[:id])
  end

  def update
    @feed = current_user.feeds.find(params[:id])

    if @feed.update(params.require(:feed).permit(PERMITTED_PARAMS))
      perform_check_with_counts!(@feed, :update)
      redirect_to edit_feed_path(@feed)
    else
      flash[:alert] = @feed.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @feed = current_user.feeds.includes(:posts, :crossposts).find(params[:id])
    post_count = @feed.posts.count
    crosspost_count = @feed.crossposts.count

    @feed.destroy!

    flash[:notice] = if post_count > 0 || crosspost_count > 0
      "Feed deleted successfully. #{post_count} post(s) and #{crosspost_count} crosspost(s) were also deleted."
    else
      "Feed deleted successfully."
    end

    redirect_to feeds_path
  end

  def check
    @feed = current_user.feeds.find(params[:id])
    perform_check_with_counts!(@feed)
    redirect_to edit_feed_path(@feed)
  end

  private

  def perform_check_with_counts!(feed, action = nil)
    result = ChecksFeedNow.new.check(feed:, cache: false)
    if result.success?
      flash[:notice] = "#{"Feed #{action}d successfully. " if action.present?}Found #{pluralize(result.data[:new_post_count], "new post")}."
    else
      flash[:notice] = "Feed #{action}d successfully." if action.present?
      flash[:alert] = "#{"Feed #{action}d successfully, but " if action.present?}checking the feed failed: #{result.error}"
    end
  end
end
