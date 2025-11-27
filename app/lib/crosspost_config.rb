CrosspostConfig = Struct.new(
  :url,
  :url_transformer, # <-- can only be set by platform defaults in code, b/c it's a lambda
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
  :format_string,
  :truncate,
  :truncation_marker, # <-- can only be set by platform defaults in code
  :append_url,
  :append_url_if_truncated,
  :append_url_spacer,
  :append_url_label,
  :append_url_label_supported, # <-- can only be set by platform defaults in code, b/c only supported by bsky
  :attach_link,
  :og_image,
  :og_title,
  :og_description,
  :channel,
  :platform_overrides,
  :media,
  keyword_init: true
)
