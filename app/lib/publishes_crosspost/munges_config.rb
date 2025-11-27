class PublishesCrosspost
  class MungesConfig
    # Platform Defaults -> Account settings -> Post settings -> Post+platform override settings
    def munge(crosspost, platform_defaults)
      options = platform_defaults
        .merge(crosspost.account.attributes.symbolize_keys.slice(*PublishesCrosspost::OVERRIDABLE_FIELDS.keys).compact)
        .merge(crosspost.post.attributes.symbolize_keys.slice(
          :url,
          :alternate_url,
          :related_url,
          :short_url,
          :author_name,
          :author_email,
          :title,
          :subtitle,
          :summary,
          :content,
          :syndicate,
          *PublishesCrosspost::OVERRIDABLE_FIELDS.keys,
          :og_title,
          :og_description,
          :media,
          :channel
        ).compact).merge(
          (crosspost.post.platform_overrides[crosspost.account.platform_tag]&.symbolize_keys || {}).compact
        )

      CrosspostConfig.new(**options)
    end
  end
end
