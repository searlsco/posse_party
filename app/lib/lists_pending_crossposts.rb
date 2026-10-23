class ListsPendingCrossposts
  include Rails.application.routes.url_helpers

  Listing = Struct.new(:syndication_paused, :crossposts, keyword_init: true)

  def initialize
    @composes_crosspost_preview = ComposesCrosspostPreview.new
    @matches_platform_api = PublishesCrosspost::MatchesPlatformApi.new
  end

  def list(user, url_options:)
    Listing.new(
      syndication_paused: !user.allow_automatic_syndication,
      crossposts: user.allow_automatic_syndication ? pending_crossposts(user, url_options) : []
    )
  end

  private

  def pending_crossposts(user, url_options)
    user.crossposts
      .where(status: %w[ready failed])
      .includes(:account, :post)
      .order(created_at: :asc)
      .filter_map { |crosspost| format_pending_crosspost(crosspost, url_options) }
  end

  def format_pending_crosspost(crosspost, url_options)
    content = @composes_crosspost_preview.compose(crosspost).data
    return nil if content.blank?

    compose_url = @matches_platform_api.match(crosspost.account).manual_compose_url(content)
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
      media: @composes_crosspost_preview.media(crosspost).map { |item| item.to_h.slice(:type, :url, :alt) },
      mark_published_url: api_crosspost_url(crosspost, **url_options),
      crosspost_url: crosspost_url(crosspost, **url_options)
    }
  end
end
