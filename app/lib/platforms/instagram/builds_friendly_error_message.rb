class Platforms::Instagram
  class BuildsFriendlyErrorMessage
    SPEC_DOC_URL = "https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/media#image-specifications"
    CONTAINER_DOC_URL = "https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-container"
    ERROR_CODES_DOC_URL = "https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/error-codes"

    def build(error, media_type:, action_description:)
      media = human_media(media_type)

      if error.is_a?(Platforms::Instagram::ProcessingError)
        <<~MSG.strip
          Instagram rejected #{media} while processing.
          Details: status_code=#{error.code}#{detail_suffix(secondary: error.subcode, label: "status")}.
          Learn more: Specs #{SPEC_DOC_URL} | Errors #{ERROR_CODES_DOC_URL} | Container #{CONTAINER_DOC_URL}
        MSG
      elsif error.is_a?(Platforms::Instagram::ApiError)
        user_title = error.raw&.dig(:error, :error_user_title)
        user_msg = error.raw&.dig(:error, :error_user_msg)
        headline = [user_title, user_msg].compact.join(" — ")
        <<~MSG.strip
          Instagram API error for #{media}: #{headline.presence || "see details below"}
          Details: code=#{error.code}#{detail_suffix(secondary: error.subcode, label: "subcode")}.
          Learn more: Specs #{SPEC_DOC_URL} | Errors #{ERROR_CODES_DOC_URL}
        MSG
      else
        <<~MSG.strip
          Instagram error while #{action_description}.
          Learn more: Specs #{SPEC_DOC_URL} | Errors #{ERROR_CODES_DOC_URL}
        MSG
      end
    end

    private

    def human_media(media_type)
      mk = media_type.to_s.upcase
      if mk.include?("REEL") || mk.include?("VIDEO")
        "video"
      elsif mk.include?("IMAGE")
        "image"
      elsif mk.include?("CAROUSEL")
        "carousel"
      elsif mk.include?("STOR")
        "story"
      else
        "media"
      end
    end

    def detail_suffix(secondary:, label:)
      secondary ? ", #{label}=#{secondary}" : ""
    end
  end
end
