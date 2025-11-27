class Platforms::Instagram
  class Media < Struct.new(:media_type, :url, :cover_url, :container_id, keyword_init: true)
    def video?
      media_type == "VIDEO"
    end
  end
end
