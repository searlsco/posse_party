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

  private

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
