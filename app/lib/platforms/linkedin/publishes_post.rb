class Platforms::Linkedin
  class PublishesPost
    TITLE_MAX_LENGTH = 60
    DESCRIPTION_MAX_LENGTH = 4084

    Result = Struct.new(:success?, :post_urn, :url, :message)

    def initialize
      @api = CallsLinkedinApi.new
    end

    def publish(content, crosspost_config, access_token:, person_urn:, image_urn: nil, url: nil)
      return Result.new(success?: false, message: "Content is required") if content.blank?

      post_data = build_post_data(content, crosspost_config, person_urn:, image_urn:, url:)
      response = @api.call(method: :post, path: "rest/posts", body: post_data, access_token: access_token)

      if response.success?
        post_urn = response.headers["x-restli-id"]&.strip
        if post_urn.present?
          Result.new(
            success?: true,
            post_urn: post_urn,
            url: "https://www.linkedin.com/feed/update/#{post_urn}/"
          )
        else
          Result.new(
            success?: false,
            message: "LinkedIn post appeared to succeed but no post URN was returned in x-restli-id header"
          )
        end
      else
        Result.new(
          success?: false,
          message: "Failed to publish LinkedIn post. #{response.message}"
        )
      end
    end

    private

    def build_post_data(content, crosspost_config, person_urn:, image_urn:, url:)
      {
        author: person_urn,
        commentary: content,
        visibility: "PUBLIC",
        distribution: {
          feedDistribution: "MAIN_FEED",
          targetEntities: [],
          thirdPartyDistributionChannels: []
        },
        lifecycleState: "PUBLISHED",
        content: (
          if url.present?
            {
              article: {
                source: url,
                title: crosspost_config.og_title.presence || crosspost_config.title.presence || content.truncate(TITLE_MAX_LENGTH),
                description: crosspost_config.og_description.presence || crosspost_config.summary.truncate(DESCRIPTION_MAX_LENGTH),
                thumbnail: image_urn
              }.compact
            }
          end
        )
      }.compact
    end
  end
end
