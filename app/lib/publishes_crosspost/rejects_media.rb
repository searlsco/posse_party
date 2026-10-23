class PublishesCrosspost
  class RejectsMedia
    # Remembers media the platform refused, so every later attempt plans without it. Returns all refused URLs
    def reject(crosspost, media)
      (crosspost.metadata.fetch("rejected_media_urls", []) | [media.url]).tap do |rejected_urls|
        crosspost.update!(metadata: crosspost.metadata.merge("rejected_media_urls" => rejected_urls))
      end
    end
  end
end
