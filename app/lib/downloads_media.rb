require "tempfile"

class DownloadsMedia
  Download = Struct.new(:file, :content_type, :size, keyword_init: true) do
    def bytes
      file.rewind
      file.read
    end
  end

  # Streams the media at url to a tempfile (videos can be hundreds of megabytes),
  # raising UnsupportedMediaError if it's larger than max_bytes
  def download(media, max_bytes: nil)
    file = Tempfile.new("posse_party_media", binmode: true)
    response = HTTParty.get(media.url, follow_redirects: true, stream_body: true) do |fragment|
      file.write(fragment) if fragment.code == 200
      if max_bytes && file.size > max_bytes
        raise PublishesCrosspost::UnsupportedMediaError.new(media, "#{media.url} is larger than the #{ActiveSupport::NumberHelper.number_to_human_size(max_bytes)} limit")
      end
    end
    raise "Failed to download #{media.url} (HTTP #{response.code})" unless response.success?

    file.flush
    file.rewind
    Download.new(
      file:,
      # The bytes themselves win over a generic or missing Content-Type (e.g. application/octet-stream)
      content_type: Marcel::MimeType.for(file, name: media.url.split(/[?#]/).first, declared_type: response.headers["content-type"].to_s.split(";").first.presence),
      size: file.size
    ).tap { file.rewind }
  end
end
