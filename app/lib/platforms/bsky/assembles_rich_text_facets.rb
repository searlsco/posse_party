class Platforms::Bsky::AssemblesRichTextFacets
  # Name of the game here is to take something output by IdentifiesPatternRanges
  # (which exists to identify unbreakable tokens) and use the embedded metadata
  # about which of these things are hashtags and links to construct the rich text
  # facet hash that bluesky wants in order to render links and hashtags
  def assemble(content, pattern_ranges)
    pattern_ranges.reject { |range|
      # the content may have been truncated, in which case we don't want/need to submit those facets
      range[:byte_index] >= content.bytesize
    }.map { |range|
      if range[:type] == :tag
        facet_for_tag(range)
      elsif range[:type] == :link
        facet_for_link(range)
      end
    }
  end

  private

  # Per the docs, bsky's byte ranges are inclusive on both ends
  # https://docs.bsky.app/docs/advanced-guides/post-richtext
  def bsky_byte_range_for(range)
    {
      "byteStart" => range[:byte_index],
      "byteEnd" => range[:byte_index] + range[:byte_length]
    }
  end

  def facet_for_tag(range)
    {
      "$type" => "app.bsky.richtext.facet",
      "index" => bsky_byte_range_for(range),
      "features" => [
        {
          "tag" => range[:substring].delete_prefix("#"),
          "$type" => "app.bsky.richtext.facet#tag"

        }
      ]
    }
  end

  def facet_for_link(range)
    url = UrlUtils.ensure_protocol(range[:substring])

    {
      "$type" => "app.bsky.richtext.facet",
      "index" => bsky_byte_range_for(range),
      "features" => [
        {
          "uri" => url,
          "$type" => "app.bsky.richtext.facet#link"
        }
      ]
    }
  end
end
