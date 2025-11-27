class PostsController < MembersController
  include GearedPagination::Controller

  set_tab :posts

  POSTS_PER_PAGE = 30

  def index
    @query = params[:q]&.strip

    if @query.present?
      search_result = SearchesPosts.new.search(
        current_user,
        @query,
        page: params[:page]&.to_i || 1,
        per_page: POSTS_PER_PAGE
      )
      if search_result.success?
        data = search_result.data
        @posts = data[:posts].limit(POSTS_PER_PAGE)
        @page = OpenStruct.new(number: data[:current_page], last?: !data[:has_more])
      else
        @posts = []
        @page = OpenStruct.new(number: 1, last?: true)
        flash.now[:alert] = search_result.error
      end
    else
      @posts = set_page_and_extract_portion_from current_user.posts
        .includes(:feed, crossposts: [:account])
        .order("posts.remote_published_at DESC"), per_page: POSTS_PER_PAGE
    end

    @has_feeds = current_user.feeds.exists?
    @has_accounts = current_user.accounts.exists?

    respond_to do |format|
      format.html
      format.turbo_stream if turbo_frame_request?
    end
  end

  def show
    @post = current_user.posts.includes(:feed, crossposts: :account).find(params[:id])
    @has_feeds = current_user.feeds.exists?
    @has_accounts = current_user.accounts.exists?
    @eligible_accounts = CreatesCrosspostForPost.new.eligible_accounts(user: current_user, post: @post)
  end

  def create_crosspost
    @post = current_user.posts.find(params[:id])
    result = CreatesCrosspostForPost.new.create(user: current_user, post: @post, account_id: params.dig(:crosspost, :account_id))

    if result.success?
      crosspost = result.data
      redirect_to crosspost_path(crosspost), notice: "Created crosspost for #{crosspost.account.notification_label}"
    else
      redirect_to post_path(@post), alert: result.error
    end
  end

  def destroy
    @post = current_user.posts.find(params[:id])
    outcome = DeletesPost.new.delete(@post)

    if outcome.success?
      redirect_to posts_path, notice: outcome.message
    else
      redirect_to post_path(@post), alert: outcome.message
    end
  end
end
