module CrosspostConfigHelper
  OVERRIDE_FIELD_LABELS = {
    format_string: "Format String",
    truncate: "Truncate Content",
    append_url: "Always Append URL",
    append_url_if_truncated: "Append URL If Truncated",
    append_url_spacer: "Spacer Before Appended URL",
    append_url_label: "Appended URL Label",
    attach_link: "Attach Website Card",
    og_image: "OpenGraph Image URL",
    platform_overrides: "Platform Overrides (JSON)"
  }.freeze

  def label_for(attribute_name)
    text = OVERRIDE_FIELD_LABELS.fetch(attribute_name) { attribute_name.to_s.humanize }
    url = doc_url(attribute_name)
    return text unless url

    safe_join([
      ERB::Util.html_escape(text),
      " (".html_safe,
      link_to("More info", url, class: "text-accent underline", target: "_blank", rel: "noopener"),
      ")".html_safe
    ])
  end

  def default_preserving_boolean_select_options(default_label: "-- Default --")
    [[default_label, ""], ["False", "false"], ["True", "true"]]
  end

  def override_default_details(default:, source: nil)
    segments = [default_label_segment(default)]
    segments << content_tag(:em, "From: #{ERB::Util.html_escape(source)}") if source
    safe_join(segments, tag.br)
  end

  def doc_url(attribute_name)
    doc_path("format-string") if attribute_name == :format_string
  end

  private

  def default_label_segment(default)
    safe_join([
      content_tag(:strong, "Default:"),
      " ".html_safe,
      default_value_segment(default)
    ])
  end

  def default_value_segment(default)
    case default
    when nil
      content_tag(:em, "(None)")
    when String
      return content_tag(:em, "Empty string") if default.empty?
      chip(default)
    else
      chip(default.to_s)
    end
  end

  def chip(text)
    content_tag(
      :span,
      text,
      class: "inline-block rounded bg-secondary px-2 py-0.5 font-mono text-xs text-primary whitespace-pre"
    )
  end
end
