class PublishesCrosspost
  # This is a fucking nightmare FYI nbd
  # Basically, if you want to truncate content to fit a social post (blog, tweet, etc.),
  # you need to be careful not to cut off URLs, hashtags, or else you might end up generating
  # invalid URLs and unintentional hashtags and mentions in the truncated content.
  # So this uses a class (IdentifiesPatternRanges) which will mark the start and end of
  # every offending match in the content, then the TruncatesContent class will use that
  # information to truncate the content in a way that doesn't cut off any of those matches.
  #
  # When space allows, add a marker (…) to the end of the string, but if you can squeeze in one more unbreakable
  # token (e.g. URL, hashtag) before the marker, leaves it off.
  class TruncatesContent
    def truncate(content, limit, counter:, unbreakables:, marker: "…")
      content = content.strip
      return content if counter.call(content) <= limit
      chars = split(content)
      unbreakables = unbreakables.map { |match| normalize_match(match) }

      marker_size = counter.call(marker)
      limit_less_marker = limit - marker_size # Need room for the ellipsis or ⋯ or whatever

      unbreakable_token = unbreakables.select { |match| intersects?(match, limit_less_marker) }
        .min_by { |match| match[:index] }

      truncated_chars = if unbreakable_token.present?
        if counter.call((perfect_fit = chars[0...(unbreakable_token[:index] + unbreakable_token[:length])]).join) <= limit
          # include the unbreakable token if it fits without the marker appended
          perfect_fit
        else
          chars[0...unbreakable_token[:index]]
        end
      else
        chars[0...limit_less_marker]
      end

      truncated_str = truncated_chars.join.strip
      if unbreakables.select { |match| intersects?(match, split(truncated_str).size - 1) }.any?
        # If there's room for the marker after a space, do that
        if counter.call(spaced_marker = "#{truncated_str} #{marker}") <= limit
          spaced_marker
        else
          # otherwise just end on the unbreakable token itself
          truncated_str
        end
      else
        "#{truncated_str}#{marker}"
      end
    end

    private

    def split(content)
      content.grapheme_clusters
    end

    def normalize_match(match)
      {substring: match[:substring], index: match[:grapheme_index], length: match[:grapheme_length]}
    end

    def intersects?(match, limit)
      match[:index] < limit && (match[:index] + match[:length]) > limit
    end
  end
end
