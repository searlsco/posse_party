class Platforms::Mastodon
  class CountsToot
    USER_DOMAIN_PATTERN = /(@\w+)(@\S+)/

    def call(content)
      content.gsub(Patterns::URL) { |url|
        if url.start_with?("http://", "https://")
          "x" * 23
        else
          url
        end
      }.gsub(USER_DOMAIN_PATTERN, '\1').grapheme_clusters.size
    end
  end
end
