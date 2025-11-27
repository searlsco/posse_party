module Platforms
  DEFAULT_CROSSPOST_OPTIONS = {
    syndicate: true,
    url_transformer: nil,
    format_string: "{{title}}",
    truncate: true,
    truncation_marker: "…",
    append_url: false,
    append_url_if_truncated: false,
    append_url_spacer: " ",
    append_url_label_supported: false,
    append_url_label: nil,
    attach_link: false,
    og_image: nil,
    og_title: nil,
    og_description: nil,
    channel: "feed"
  }.freeze
end
