module UrlUtils
  def self.ensure_protocol(url)
    if /\A(?:https?|ftp):\/\//.match?(url)
      url
    else
      "https://#{url}"
    end
  end
end
