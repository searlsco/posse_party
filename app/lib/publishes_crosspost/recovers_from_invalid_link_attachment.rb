class PublishesCrosspost
  class RecoversFromInvalidLinkAttachment
    def initialize
      @composes_crosspost_content = ComposesCrosspostContent.new
    end

    def recover(crosspost, crosspost_config, api, failing_content:)
      crosspost_config.attach_link = false

      if !failing_content.string.include?(crosspost_config.url)
        # Try again, this time with the URL appended, regardless of configuration
        crosspost_config.append_url = true
        crosspost_content = @composes_crosspost_content.compose(crosspost_config, api.post_constraints)
        api.publish!(crosspost, crosspost_config, crosspost_content)
      else
        # Try again, this time merely without the attachment
        api.publish!(crosspost, crosspost_config, failing_content)
      end
    end
  end
end
