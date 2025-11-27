class Platforms::Linkedin
  class SyndicatesLinkedinPost
    def initialize
      @splits_content_from_organic_url = SplitsContentFromOrganicUrl.new
      @scrapes_og_image = ScrapesOgImage.new
      @initiates_image_upload = InitiatesImageUpload.new
      @uploads_image = UploadsImage.new
      @publishes_post = PublishesPost.new
    end

    def syndicate!(crosspost, crosspost_config, crosspost_content)
      return PublishesCrosspost::Result.new(success?: false, message: "Missing access token") if (access_token = crosspost.account.credentials["access_token"]).blank?
      return PublishesCrosspost::Result.new(success?: false, message: "Missing person URN") if (person_urn = crosspost.account.credentials["person_urn"]).blank?

      content, url = @splits_content_from_organic_url.split(crosspost_config, crosspost_content)
      og_image = (url == crosspost_config.url) ? crosspost_config.og_image : @scrapes_og_image.scrape(url)
      image_urn = if url.present? &&
          og_image.present? &&
          (upload_init_result = @initiates_image_upload.initiate(access_token:, person_urn:)).success? &&
          @uploads_image.upload(og_image, upload_init_result.upload_url, access_token:).success?
        upload_init_result.image_urn
      end

      # Escape special characters that LinkedIn API has issues with
      # Based on known LinkedIn API bug where parentheses cause content truncation
      escaped_content = content.gsub(/([\\|{}@\[\]()<>#*_~])/) { "\\#{$1}" }

      if (publish_result = @publishes_post.publish(escaped_content, crosspost_config, access_token:, person_urn:, image_urn:, url:)).success?
        crosspost.update!(
          remote_id: publish_result.post_urn,
          url: publish_result.url,
          content: content,
          status: "published",
          published_at: Now.time
        )
        PublishesCrosspost::Result.new(success?: true)
      else
        PublishesCrosspost::Result.new(success?: false, message: "Failed to publish LinkedIn post. Error: #{publish_result.message}")
      end
    rescue => e
      PublishesCrosspost::Result.new(success?: false, message: "An unexpected error occurred while crossposting to LinkedIn", error: e)
    end
  end
end
