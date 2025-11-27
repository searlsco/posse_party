class PublishesCrosspost
  class ComposesCrosspostContent
    def initialize
      @applies_format_string = AppliesFormatString.new
      @identifies_pattern_ranges = IdentifiesPatternRanges.new
      @truncates_content = TruncatesContent.new
    end

    def compose(crosspost_config, post_constraints)
      # analyzing and potentially transforming content based on special parsed types (links and hashtags)
      content = @applies_format_string.apply(crosspost_config)
      url_analysis = @identifies_pattern_ranges.identify(content, post_constraints[:url_pattern], transformer: crosspost_config.url_transformer, metadata: {type: :link})
      content = url_analysis.string if crosspost_config.url_transformer.present?
      hashtag_analysis = @identifies_pattern_ranges.identify(content, post_constraints[:hashtag_pattern], metadata: {type: :tag})

      # appended_url stuff
      url_label = if crosspost_config.append_url_label_supported && crosspost_config.append_url_label.present?
        crosspost_config.append_url_label
      else
        crosspost_config.url
      end
      url_appendment = crosspost_config.append_url_spacer.to_s + url_label.to_s
      candidate = if crosspost_config.append_url
        content.blank? ? url_appendment.sub(/^\s+/, "") : (content + url_appendment)
      else
        content
      end

      pattern_ranges = url_analysis.pattern_ranges + hashtag_analysis.pattern_ranges

      content = if post_constraints[:counter].call(candidate) <= post_constraints[:character_limit]
        url_label_was_appended = crosspost_config.append_url
        candidate
      elsif !crosspost_config.truncate
        raise PublishesCrosspost::UnretriableError, "Content is too long to post without truncation"
      elsif crosspost_config.append_url || crosspost_config.append_url_if_truncated
        url_label_was_appended = true
        @truncates_content.truncate(
          content,
          post_constraints[:character_limit] - post_constraints[:counter].call(url_appendment),
          counter: post_constraints[:counter],
          unbreakables: pattern_ranges,
          marker: crosspost_config.truncation_marker
        ) + url_appendment
      else
        @truncates_content.truncate(
          content,
          post_constraints[:character_limit],
          counter: post_constraints[:counter],
          unbreakables: pattern_ranges,
          marker: crosspost_config.truncation_marker
        )
      end

      IdentifiesPatternRanges::Result.new(content, combined_pattern_ranges(content, crosspost_config.url, url_label, url_label_was_appended, pattern_ranges))
    end

    private

    # This is a hack to support custom labels for appended URLs. I'd have preferred to add this more naturally (append the URL, and transform it)
    # but the need to count spaces to determine whether to truncate main content and whether to append was just too much
    def combined_pattern_ranges(content, url, url_label, url_label_was_appended, pattern_ranges)
      return pattern_ranges unless url_label_was_appended
      appended_url_analysis = @identifies_pattern_ranges.identify(content, /#{Regexp.escape(url_label)}\z/, metadata: {type: :link})
      pattern_ranges + [appended_url_analysis.pattern_ranges.last.merge(substring: url)]
    end
  end
end
