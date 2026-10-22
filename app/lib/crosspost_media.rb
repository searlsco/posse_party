CrosspostMedia = Struct.new(:type, :url, :poster_url, :alt, keyword_init: true) do
  def image?
    type == "image"
  end

  def video?
    type == "video"
  end
end
