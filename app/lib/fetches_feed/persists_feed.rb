class FetchesFeed
  class PersistsFeed
    def initialize
      @converts_html_to_plaintext = ConvertsHtmlToPlaintext.new
      @applies_post_overrides = AppliesPostOverrides.new
    end

    def persist(feed, parsed_feed, etag_header:, last_modified_header:)
      duplicate_ids = parsed_feed.entries.map(&method(:remote_id_for)).tally.select { |_, count| count > 1 }.keys
      raise StandardError, "Feed contains multiple entries with the same id: #{duplicate_ids.first}" if duplicate_ids.any?

      Feed.transaction do
        Post.upsert_all(
          parsed_feed.entries.map { |entry|
            entry_url = entry_url_for(entry)

            @applies_post_overrides.apply({
              feed_id: feed.id,
              remote_id: remote_id_for(entry),
              remote_published_at: entry.published,
              remote_updated_at: entry.updated,
              url: entry_url,
              alternate_url: links_by_rel(entry, "alternate").first,
              related_url: links_by_rel(entry, "related").first,
              short_url: links_by_rel(entry, "shorturl").first,
              author_name: entry.author,
              author_email: entry.author_email,
              title: entry.title,
              subtitle: entry.subtitle,
              summary: @converts_html_to_plaintext.convert(entry.summary),
              content: @converts_html_to_plaintext.convert(entry.content),

              # Can only be set via <posse:post> JSON; must be set to sastisfy "All objects being inserted must have the same keys" in rails' insert_all impl
              # this means that this app can't modify these values after the fact as the current impl will always overwrite them
              syndicate: nil,
              format_string: nil,
              truncate: nil,
              append_url: nil,
              append_url_if_truncated: nil,
              append_url_spacer: nil,
              append_url_label: nil,
              attach_link: nil,
              og_image: nil,
              og_title: nil,
              og_description: nil,
              channel: nil,
              platform_overrides: {},
              media: []
            }, entry.syndication_config)
          },
          unique_by: [:feed_id, :remote_id]
        )

        feed.update!(
          etag_header: etag_header,
          last_modified_header: last_modified_header,
          last_checked_at: Now.time
        )
      end
    end

    private

    def remote_id_for(entry)
      entry.entry_id.presence || entry_url_for(entry)
    end

    def entry_url_for(entry)
      links_by_rel(entry, "shorturl").first || links_by_rel(entry, "alternate").first || entry.links.first
    end

    def links_by_rel(entry, rel)
      return [] if entry.link_rels.blank?
      link_indices = entry.link_rels.each_index.select { |i|
        entry.link_rels[i] == rel
      }
      entry.links.values_at(*link_indices)
    end
  end
end
