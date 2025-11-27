class Platforms::Linkedin
  class ScrapesOgImage
    def scrape(url)
      return if url.blank?

      if (response = URI.parse(url).open(redirect: true)) &&
          response.content_type&.include?("html")
        doc = Nokogiri::HTML(response.read)
        normalize_url(doc&.at('meta[property="og:image"]')&.[]("content"))
      end
    rescue
      nil
    end

    private

    def normalize_url(raw_url)
      return unless raw_url&.match?(/\A(https?:\/\/|\/\/)/)

      raw_url.start_with?("//") ? "https:#{raw_url}" : raw_url
    end
  end
end
