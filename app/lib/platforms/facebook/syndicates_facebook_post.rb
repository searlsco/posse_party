class Platforms::Facebook
  class SyndicatesFacebookPost
    def initialize
      @splits_content_from_organic_url = SplitsContentFromOrganicUrl.new
    end

    def syndicate!(crosspost, crosspost_config, crosspost_content)
      return PublishesCrosspost::Result.new(success?: false, message: "Missing page_id") if (page_id = crosspost.account.credentials["page_id"]).blank?
      return PublishesCrosspost::Result.new(success?: false, message: "Missing page_access_token") if (page_access_token = crosspost.account.credentials["page_access_token"]).blank?

      result = post_to_facebook!(crosspost, crosspost_config, crosspost_content, page_id, page_access_token)

      if result[:success] && (full_post_id = result.dig(:data, :id))
        post_id = full_post_id.split("_").last
        crosspost.update!(
          remote_id: post_id,
          url: "https://www.facebook.com/#{page_id}/posts/#{post_id}",
          content: crosspost_content,
          status: "published",
          published_at: Now.time
        )
        PublishesCrosspost::Result.new(success?: true)
      else
        PublishesCrosspost::Result.new(
          success?: false,
          message: "Failed to create Facebook post. Response: #{result[:data]}"
        )
      end
    rescue => e
      PublishesCrosspost::Result.new(success?: false, message: "Failed to syndicate to Facebook", error: e)
    end

    private

    def post_to_facebook!(crosspost, crosspost_config, crosspost_content, page_id, page_access_token)
      content, url = @splits_content_from_organic_url.split(crosspost_config, crosspost_content)
      response = HTTParty.post("#{::Platforms::Facebook::API_BASE_URL}#{page_id}/feed",
        body: {
          message: content,
          link: url,
          published: true,
          access_token: page_access_token
        }.compact,
        format: :plain)

      {
        success: response.success?,
        data: RelaxedJson.parse(response)
      }
    end
  end
end
