class Platforms::Bsky::AttachesWebCard
  def attach!(crosspost_config, record_manager)
    {
      "$type" => "app.bsky.embed.external",
      "external" => {
        "uri" => crosspost_config.url,
        "title" => crosspost_config.og_title.presence || crosspost_config.title,
        "description" => crosspost_config.og_description.presence || crosspost_config.summary,
        "thumb" => upload_thumbnail!(crosspost_config.og_image, record_manager)
      }.compact
    }
  end

  private

  def upload_thumbnail!(image_url, record_manager)
    return if image_url.blank?

    image_data, content_type = download_image(image_url)
    raise "Failed to download og_image: #{image_url}" unless image_data

    # Dropping down to do this ourselves b/c the bsky gem assumes you're reading the image from a file
    # https://github.com/ShreyanJain9/bskyrb/blob/main/lib/bskyrb/records.rb#L36
    upload_response = HTTParty.post(
      record_manager.upload_blob_uri(record_manager.session.pds),
      body: image_data,
      headers: record_manager.default_authenticated_headers(record_manager.session).merge("Content-Type" => content_type)
    )
    raise "Failed to upload og_image: #{image_url} to Bsky. Response: #{upload_response}" unless upload_response.success?

    upload_response["blob"]
  end

  def download_image(image_url)
    uri = URI.parse(image_url)
    response = Net::HTTP.get_response(uri)
    return unless response.is_a?(Net::HTTPSuccess)

    content_type = response.content_type || Marcel::MimeType.for(Pathname.new(uri.path))
    [response.body, content_type]
  end
end
