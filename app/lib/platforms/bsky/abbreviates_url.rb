class Platforms::Bsky
  class AbbreviatesUrl
    def call(url)
      "#{URI.parse(UrlUtils.ensure_protocol(url)).host}/…"
    rescue
      url
    end
  end
end
