class Api::CrosspostsController < ApiController
  def index
    remote_id = params[:id]

    if remote_id.blank?
      render json: all_crossposts
    elsif (post = find_user_post(remote_id)).nil?
      render json: {error: "Post not found"}, status: :not_found
    else
      render json: crossposts_for(post)
    end
  end

  # Crossposts that can't be published via API (or already failed trying) but whose
  # platform offers a prefilled compose URL, so they can be posted by hand instead.
  def pending
    render json: {crossposts: pending_crossposts}
  end

  def update
    crosspost = current_user.crossposts.includes(:account).find_by(id: params[:id])

    if crosspost.nil?
      render json: {error: "Crosspost not found"}, status: :not_found
    elsif (outcome = MarksCrosspostPublished.new.mark(crosspost, params[:url])).failure?
      render json: {error: outcome.message}, status: :unprocessable_content
    else
      render json: format_crosspost(crosspost)
    end
  end

  private

  def pending_crossposts
    composes_crosspost_preview = ComposesCrosspostPreview.new
    matches_platform_api = PublishesCrosspost::MatchesPlatformApi.new

    current_user.crossposts
      .where(status: %w[ready failed])
      .includes(:account, :post)
      .order(created_at: :asc)
      .filter_map { |crosspost| format_pending_crosspost(crosspost, composes_crosspost_preview, matches_platform_api) }
  end

  def format_pending_crosspost(crosspost, composes_crosspost_preview, matches_platform_api)
    content = composes_crosspost_preview.compose(crosspost).data
    return nil if content.blank?

    compose_url = matches_platform_api.match(crosspost.account).manual_compose_url(content)
    return nil if compose_url.blank?

    {
      id: crosspost.id,
      platform: crosspost.account.platform_tag,
      account: crosspost.account.label,
      status: crosspost.status,
      post_url: crosspost.post.url,
      content: content,
      compose_url: compose_url,
      # The compose URL can't carry media, so whoever composes the post attaches these themselves
      media: composes_crosspost_preview.media(crosspost).map { |item| item.to_h.slice(:type, :url, :alt) },
      mark_published_url: api_crosspost_url(crosspost),
      crosspost_url: crosspost_url(crosspost)
    }
  end

  def find_user_post(remote_id)
    Post.joins(feed: :user)
      .where(users: {id: current_user.id})
      .find_by(remote_id: remote_id)
  end

  def crossposts_for(post)
    post.crossposts
      .joins(:account)
      .where(accounts: {user: current_user})
      .where.not(url: nil)
      .includes(:account)
      .map { |crosspost| format_crosspost(crosspost) }
  end

  def format_crosspost(crosspost)
    last_failure = crosspost.failures.last
    {
      platform: crosspost.account.platform_tag,
      account: crosspost.account.label,
      url: crosspost.url,
      status: crosspost.status,
      crosspost_url: crosspost_url(crosspost),
      error: last_failure&.dig("message") || last_failure&.dig(:message)
    }
  end

  def all_crossposts
    posts = Post.joins(feed: :user, crossposts: :account)
      .where(users: {id: current_user.id})
      .where(accounts: {user: current_user})
      .where.not(crossposts: {url: nil})
      .order("posts.updated_at DESC")
      .distinct
      .includes(crossposts: :account)

    crossposts_map = {}
    most_recent_updated_at = nil

    posts.each do |post|
      items = post.crossposts
        .select { |cp| cp.account.user_id == current_user.id && cp.url.present? }
        .map { |cp| format_crosspost(cp) }

      if items.any?
        crossposts_map[post.remote_id] = items
        most_recent_updated_at = post.updated_at if most_recent_updated_at.nil? || post.updated_at > most_recent_updated_at
      end
    end

    {
      crossposts: crossposts_map,
      updated_at: most_recent_updated_at&.iso8601
    }
  end
end
