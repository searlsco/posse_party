class Platforms::Instagram
  class Post < Struct.new(
    :media_type,  # "IMAGE" | "REELS" | "CAROUSEL" | "STORIES"
    :url,         # source URL for attribution/caption building
    :medias,      # array<Platforms::Instagram::Media>
    :caption,     # string or nil for stories
    keyword_init: true
  )
  end
end
