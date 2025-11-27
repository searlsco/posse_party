class PublishesCrosspost
  class AppliesFormatString
    def apply(config)
      config = config.to_h # <- Gracefully nil out of non-existent config keys
      config[:format_string]
        .gsub(/\{\{([^{}]+)\}\}/) {
          key = Regexp.last_match(1).strip.to_sym
          config[key] || ""
        }
        .unicode_normalize(:nfc)
        .squeeze(" ")
        .gsub(/ +\n/, "\n")
        .strip
    end
  end
end
