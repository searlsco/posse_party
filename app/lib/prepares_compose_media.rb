class PreparesComposeMedia
  Image = Struct.new(:bytes, :filename, keyword_init: true)

  MAX_BYTES = 25.megabytes
  MAX_DIMENSION = 4096

  def initialize
    @composes_crosspost_preview = ComposesCrosspostPreview.new
    @downloads_media = DownloadsMedia.new
  end

  # The crosspost's index-th attachment as a PNG (the one image format browsers can put on the
  # clipboard), for pasting into a platform's own composer. Only images are served: decoding and
  # re-encoding them (with the download and dimensions capped) means nothing but image data can
  # come back from whatever the URL points at
  def prepare(crosspost, index)
    item = @composes_crosspost_preview.media(crosspost)[index]
    return unless item&.image?

    require "vips"
    Image.new(
      bytes: Vips::Image.thumbnail_buffer(@downloads_media.download(item, max_bytes: MAX_BYTES).bytes, MAX_DIMENSION, size: :down).write_to_buffer(".png"),
      filename: "#{File.basename(item.url.split(/[?#]/).first, ".*")}.png"
    )
  rescue PublishesCrosspost::UnsupportedMediaError, Vips::Error
    nil
  end
end
