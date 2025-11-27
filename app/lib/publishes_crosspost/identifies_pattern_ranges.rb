class PublishesCrosspost
  class IdentifiesPatternRanges
    Result = Struct.new(:string, :pattern_ranges)

    URL_TO_DOMAIN_TRANSFORMER = ->(url) {
      URI.parse(UrlUtils.ensure_protocol(url)).host
    }

    def identify(str, pattern, transformer: nil, metadata: {})
      pattern_ranges = []
      str.scan(pattern) do |substring|
        match = Regexp.last_match
        pattern_ranges << {
          substring:,
          grapheme_index: str[0...match.begin(0)].grapheme_clusters.count,
          grapheme_length: substring.grapheme_clusters.count,
          char_index: match.begin(0),
          char_length: substring.length,
          byte_index: str[0...match.begin(0)].bytesize,
          byte_length: substring.bytesize
        }.merge(metadata)
      end

      if transformer.present?
        transform(str, pattern_ranges, transformer:, metadata:)
      else
        Result.new(str, pattern_ranges)
      end
    end

    private

    def transform(str, pattern_ranges, transformer:, metadata:)
      output = ""
      last_end = 0
      updated = []

      pattern_ranges.each do |range|
        output += str[last_end...range[:char_index]]
        replaced = transformer.call(range[:substring])
        updated << {
          substring: range[:substring],
          char_index: output.length,
          char_length: replaced.length,
          grapheme_index: output.grapheme_clusters.count,
          grapheme_length: replaced.grapheme_clusters.count,
          byte_index: output.bytesize,
          byte_length: replaced.bytesize
        }.merge(metadata)
        output += replaced
        last_end = range[:char_index] + range[:char_length]
      end

      output += str[last_end..]
      Result.new(output, updated)
    end
  end
end
