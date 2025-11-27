class DeterminesProvenanceOfCrosspostConfig
  Provenance = Struct.new(:defaults, :sources, keyword_init: true) do
    def default(key)
      defaults[key]
    end

    def source(key)
      sources[key]
    end
  end

  def determine(crosspost, platform_defaults)
    tag = crosspost.account.platform_tag
    platform_override_values = (crosspost.post.platform_overrides[tag] || {}).with_indifferent_access

    sources = PublishesCrosspost::OVERRIDABLE_FIELDS.keys
      .map { |key|
        src = if platform_override_values.key?(key) && !platform_override_values[key].nil?
          "Post platform override"
        elsif !crosspost.post.public_send(key).nil?
          "Post override"
        elsif !crosspost.account.public_send(key).nil?
          "Account override"
        else
          "Platform default"
        end
        [key, src]
      }.to_h

    Provenance.new(defaults: platform_defaults, sources: sources)
  end
end
