class Platforms::Instagram::TranslatesInstagramPost
  def from_crosspost(crosspost, channel: "feed")
    post = crosspost.post
    medias = post.media
      .take((channel == "story") ? 1 : 10)
      .map { |m| instagram_media_from_post_media(m) }

    Platforms::Instagram::Post.new(
      media_type: infer_media_type(medias, channel),
      url: post.url,
      medias: medias,
      caption: ((channel == "story") ? nil : crosspost.content)
    )
  end

  def from_json(serialized_post)
    deserialized_post = JSON.parse(serialized_post, symbolize_names: true)
    Platforms::Instagram::Post.new(deserialized_post.merge(
      medias: deserialized_post.fetch(:medias, []).map { |m| Platforms::Instagram::Media.new(m) }
    ))
  end

  private

  def infer_media_type(medias, channel)
    return "STORIES" if channel == "story"
    return "CAROUSEL" if medias.size > 1
    medias.first&.video? ? "REELS" : "IMAGE"
  end

  def instagram_media_from_post_media(post_media)
    Platforms::Instagram::Media.new(
      post_media.slice("url", "container_id").merge(
        cover_url: post_media["poster_url"],
        media_type: (post_media["type"] == "video") ? "VIDEO" : "IMAGE"
      )
    )
  end
end
