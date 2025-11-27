class SearchesPosts
  def search(user, query, page: 1, per_page: 30)
    return Result.failure("User is required") if user.blank?
    return Result.failure("Query cannot be blank") if query.blank?

    scope = build_search_scope(user, query)
      .includes(:feed, crossposts: [:account])
      .joins(:crossposts)
      .distinct
      .order("posts.remote_published_at DESC")

    Result.success({
      posts: scope.offset((page - 1) * per_page).limit(per_page),
      has_more: scope.offset(page * per_page).exists?,
      current_page: page
    })
  rescue
    Result.failure("Unable to search posts at this time. Please try again.")
  end

  private

  def build_search_scope(user, query)
    sanitized_query = sanitize_query(query)
    user.posts.where(
      "(COALESCE(posts.title, '') || ' ' || COALESCE(posts.url, '') || ' ' || COALESCE(posts.content, '')) ILIKE ?",
      "%#{sanitized_query}%"
    )
  end

  def sanitize_query(query)
    query.to_s.strip.gsub(/[%_\\]/) { |char| "\\#{char}" }
  end
end
