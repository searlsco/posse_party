class SplitsContentFromOrganicUrl
  def split(crosspost_config, crosspost_content)
    if crosspost_config.attach_link && crosspost_config.url.present?
      [crosspost_content, crosspost_config.url]
    elsif (match = crosspost_content.match(/\A(.+?)\s*(#{Patterns::URL})\s*\z/mo))
      [match[1].strip, match[2].strip]
    else
      [crosspost_content, nil]
    end
  end
end
