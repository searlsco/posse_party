module Platforms
  # What a platform can attach to a single post. A nil max means no limit beyond the others.
  MediaConstraints = Struct.new(:max_images, :max_videos, :max_items, :mixable, keyword_init: true)
end
